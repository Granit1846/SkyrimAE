// src/TDL_Twitch.cpp
// Native Twitch integration: Device Code login (public client, no secret), EventSub over WebSocket,
// events mapped to TDL actions via TDL_Twitch.ini and queued through the existing scheduler.
#include "TDL_Twitch.h"
#include "TDL_PipeServer.h"

// CommonLib headers must precede Windows.h (its macros break RE types)
#ifndef TDL_TWITCH_HARNESS
#include <RE/M/Misc.h>
#include <SKSE/SKSE.h>
#endif

#include <Windows.h>
#include <shellapi.h>
#include <wincrypt.h>
#include <winhttp.h>

#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif

#include <nlohmann/json.hpp>
#include <spdlog/spdlog.h>


#include <algorithm>
#include <charconv>
#include <cctype>
#include <atomic>
#include <chrono>
#include <deque>
#include <fstream>
#include <mutex>
#include <optional>
#include <random>
#include <string>
#include <thread>

using json = nlohmann::json;
using namespace std::literals;

namespace
{
	constexpr const char* kClientId = "ki8umjlmg23b9hiuq2o20usjvjpayn";
	constexpr const char* kScopes = "channel:read:redemptions bits:read user:read:chat channel:read:polls";
	constexpr const char* kEventSubUrl = "wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30";

	// Twitch event source codes understood by the scheduler (lower = higher priority).
	constexpr int kSourceBits = 1;
	constexpr int kSourcePoints = 2;
	constexpr int kSourceVote = 3;

	using Clock = std::chrono::steady_clock;

	// ---------------------------------------------------------------- host (game vs. test harness)

	std::filesystem::path IniPath()
	{
		return std::filesystem::current_path() / "Data" / "SKSE" / "Plugins" / "TDL_Twitch.ini";
	}

#ifndef TDL_TWITCH_HARNESS
	std::filesystem::path TokenPath()
	{
		// Documents\My Games\Skyrim Special Edition\SKSE: per-user, never inside Data (mod managers, shared archives)
		auto dir = SKSE::log::log_directory();
		return dir ? *dir / "TDL_Twitch.token" : std::filesystem::path{};
	}

	void ShowInGame(std::string text)
	{
		if (auto* tasks = SKSE::GetTaskInterface(); tasks) {
			tasks->AddTask([t = std::move(text)] { RE::DebugMessageBox(t.c_str()); });
		}
	}
#else
	std::filesystem::path TokenPath() { return std::filesystem::temp_directory_path() / "TDL_Twitch.token"; }
	void ShowInGame(std::string text) { spdlog::info("[MESSAGE BOX] {}", text); }
#endif

	// ---------------------------------------------------------------- small helpers

	std::wstring Widen(const std::string& s)
	{
		if (s.empty()) {
			return {};
		}
		const int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
		std::wstring w(static_cast<size_t>(n), L'\0');
		MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), w.data(), n);
		return w;
	}

	std::string UrlEncode(const std::string& s)
	{
		static constexpr char kHex[] = "0123456789ABCDEF";
		std::string out;
		for (unsigned char c : s) {
			if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
				out += static_cast<char>(c);
			} else {
				out += '%';
				out += kHex[c >> 4];
				out += kHex[c & 15];
			}
		}
		return out;
	}

	std::string Trim(std::string s)
	{
		const auto ws = " \t\r\n";
		s.erase(0, s.find_first_not_of(ws));
		s.erase(s.find_last_not_of(ws) + 1);
		return s;
	}

	std::string LowerAscii(std::string s)
	{
		for (auto& c : s) {
			if (c >= 'A' && c <= 'Z') {
				c = static_cast<char>(c - 'A' + 'a');
			}
		}
		return s;
	}

	void SleepFor(std::chrono::seconds s) { std::this_thread::sleep_for(s); }

	// ---------------------------------------------------------------- HTTP (WinHTTP)

	HINTERNET g_session = nullptr;

	struct Url
	{
		bool secure = true;
		std::wstring host;
		INTERNET_PORT port = INTERNET_DEFAULT_HTTPS_PORT;
		std::wstring path;
	};

	// Accepts http/https/ws/wss URLs. TLS unless the scheme is http:// or ws:// (Twitch CLI mock server).
	std::optional<Url> ParseUrl(const std::string& url)
	{
		const auto sep = url.find("://");
		if (sep == std::string::npos) {
			return std::nullopt;
		}
		const auto scheme = LowerAscii(url.substr(0, sep));
		Url u;
		u.secure = (scheme == "https" || scheme == "wss");
		u.port = u.secure ? INTERNET_DEFAULT_HTTPS_PORT : INTERNET_DEFAULT_HTTP_PORT;

		const auto rest = url.substr(sep + 3);
		const auto slash = rest.find('/');
		auto hostPort = rest.substr(0, slash);
		u.path = Widen(slash == std::string::npos ? "/" : rest.substr(slash));

		if (const auto colon = hostPort.find(':'); colon != std::string::npos) {
			int port = 0;
			const auto p = hostPort.substr(colon + 1);
			if (std::from_chars(p.data(), p.data() + p.size(), port).ec != std::errc{} || port <= 0 || port > 65535) {
				return std::nullopt;  // bad MockUrl must not throw out of the detached thread
			}
			u.port = static_cast<INTERNET_PORT>(port);
			hostPort.resize(colon);
		}
		u.host = Widen(hostPort);
		return u;
	}

	struct HttpResponse
	{
		DWORD status = 0;  // 0 = network failure
		std::string body;
	};

	HttpResponse Http(const char* method, const std::string& url, const std::string& body, const std::string& headers)
	{
		HttpResponse r;
		const auto u = ParseUrl(url);
		if (!u) {
			return r;
		}

		HINTERNET con = WinHttpConnect(g_session, u->host.c_str(), u->port, 0);
		HINTERNET req = con ? WinHttpOpenRequest(con, Widen(method).c_str(), u->path.c_str(), nullptr, WINHTTP_NO_REFERER,
								  WINHTTP_DEFAULT_ACCEPT_TYPES, u->secure ? WINHTTP_FLAG_SECURE : 0) :
							  nullptr;
		const auto wHeaders = Widen(headers);
		const bool ok = req &&
		                WinHttpSendRequest(req, wHeaders.empty() ? WINHTTP_NO_ADDITIONAL_HEADERS : wHeaders.c_str(),
							static_cast<DWORD>(wHeaders.size()), const_cast<char*>(body.data()),
							static_cast<DWORD>(body.size()), static_cast<DWORD>(body.size()), 0) &&
		                WinHttpReceiveResponse(req, nullptr);

		if (ok) {
			DWORD size = sizeof(r.status);
			WinHttpQueryHeaders(req, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, WINHTTP_HEADER_NAME_BY_INDEX,
				&r.status, &size, WINHTTP_NO_HEADER_INDEX);
			char buf[4096];
			DWORD read = 0;
			while (WinHttpReadData(req, buf, sizeof(buf), &read) && read > 0) {
				r.body.append(buf, read);
			}
		} else {
			spdlog::warn("Twitch: {} {} failed, WinHTTP error {}", method, url, GetLastError());
		}

		if (req) {
			WinHttpCloseHandle(req);
		}
		if (con) {
			WinHttpCloseHandle(con);
		}
		return r;
	}

	HttpResponse PostForm(const std::string& url, const std::string& form)
	{
		return Http("POST", url, form, "Content-Type: application/x-www-form-urlencoded\r\n");
	}

	std::optional<json> ParseJson(const std::string& s)
	{
		auto j = json::parse(s, nullptr, false);
		if (j.is_discarded()) {
			return std::nullopt;
		}
		return j;
	}

	// ---------------------------------------------------------------- config (TDL_Twitch.ini)

	struct Config
	{
		TDL_IniData ini;
		std::filesystem::file_time_type mtime{};
	};
	Config g_cfg;

	// Re-read on change so the Configurator can edit mappings while the game runs.
	const TDL_IniData& Ini()
	{
		std::error_code ec;
		const auto t = std::filesystem::last_write_time(IniPath(), ec);
		if (!ec && t != g_cfg.mtime) {
			g_cfg.ini = TDL_LoadIni(IniPath());
			g_cfg.mtime = t;
			spdlog::info("Twitch: mapping loaded from '{}'", IniPath().string());
		}
		return g_cfg.ini;
	}

	std::string IniValue(const char* section, const std::string& key)
	{
		const auto& ini = Ini();
		const auto s = ini.find(section);
		if (s == ini.end()) {
			return {};
		}
		const auto k = s->second.find(LowerAscii(Trim(key)));
		return k == s->second.end() ? std::string{} : k->second;
	}

	bool MockMode() { return IniValue("twitch", "MockServer") == "1"; }

	// ---------------------------------------------------------------- token storage (DPAPI, current Windows user)

	void SaveRefreshToken(const std::string& token)
	{
		DATA_BLOB in{ static_cast<DWORD>(token.size()), reinterpret_cast<BYTE*>(const_cast<char*>(token.data())) };
		DATA_BLOB out{};
		if (!CryptProtectData(&in, L"TDL Twitch", nullptr, nullptr, nullptr, CRYPTPROTECT_UI_FORBIDDEN, &out)) {
			spdlog::error("Twitch: CryptProtectData failed: {}", GetLastError());
			return;
		}
		std::ofstream f(TokenPath(), std::ios::binary | std::ios::trunc);
		f.write(reinterpret_cast<const char*>(out.pbData), out.cbData);
		LocalFree(out.pbData);
	}

	std::string LoadRefreshToken()
	{
		std::ifstream f(TokenPath(), std::ios::binary);
		const std::string enc((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
		if (enc.empty()) {
			return {};
		}
		DATA_BLOB in{ static_cast<DWORD>(enc.size()), reinterpret_cast<BYTE*>(const_cast<char*>(enc.data())) };
		DATA_BLOB out{};
		if (!CryptUnprotectData(&in, nullptr, nullptr, nullptr, nullptr, CRYPTPROTECT_UI_FORBIDDEN, &out)) {
			return {};
		}
		std::string token(reinterpret_cast<const char*>(out.pbData), out.cbData);
		LocalFree(out.pbData);
		return token;
	}

	// ---------------------------------------------------------------- auth

	std::string g_access;
	std::string g_userId;
	Clock::time_point g_lastValidate{};

	enum class Auth
	{
		kOk,
		kInvalid,   // must log in again
		kNetError,  // retry later
	};

	Auth AcceptTokens(const HttpResponse& r)
	{
		const auto j = ParseJson(r.body);
		if (!j || !j->contains("access_token") || !j->contains("refresh_token")) {
			spdlog::warn("Twitch: unexpected token response {}: {}", r.status, r.body);
			return Auth::kInvalid;
		}
		g_access = (*j)["access_token"].get<std::string>();
		SaveRefreshToken((*j)["refresh_token"].get<std::string>());  // refresh tokens are one-time use: persist at once
		return Auth::kOk;
	}

	Auth Refresh()
	{
		const auto rt = LoadRefreshToken();
		if (rt.empty()) {
			return Auth::kInvalid;
		}
		const auto r = PostForm("https://id.twitch.tv/oauth2/token",
			"client_id="s + kClientId + "&grant_type=refresh_token&refresh_token=" + UrlEncode(rt));
		if (r.status == 0 || r.status >= 500) {
			return Auth::kNetError;
		}
		if (r.status != 200) {
			spdlog::warn("Twitch: refresh rejected ({}), login required", r.status);
			std::error_code ec;
			std::filesystem::remove(TokenPath(), ec);
			return Auth::kInvalid;
		}
		return AcceptTokens(r);
	}

	Auth Validate()
	{
		const auto r = Http("GET", "https://id.twitch.tv/oauth2/validate", {}, "Authorization: OAuth " + g_access + "\r\n");
		if (r.status == 0 || r.status >= 500) {
			return Auth::kNetError;
		}
		const auto j = ParseJson(r.body);
		if (r.status != 200 || !j) {
			return Auth::kInvalid;
		}
		g_userId = j->value("user_id", "");
		g_lastValidate = Clock::now();
		spdlog::info("Twitch: logged in as '{}' (id {})", j->value("login", ""), g_userId);
		return Auth::kOk;
	}

	Auth DeviceLogin()
	{
		const auto start = PostForm("https://id.twitch.tv/oauth2/device",
			"client_id="s + kClientId + "&scopes=" + UrlEncode(kScopes));
		const auto j = ParseJson(start.body);
		if (start.status != 200 || !j) {
			spdlog::warn("Twitch: device flow start failed ({}): {}", start.status, start.body);
			return start.status == 0 ? Auth::kNetError : Auth::kInvalid;
		}

		const auto deviceCode = j->value("device_code", "");
		const auto userCode = j->value("user_code", "");
		const auto uri = j->value("verification_uri", "https://www.twitch.tv/activate");
		auto interval = std::max(1, j->value("interval", 5));
		const auto deadline = Clock::now() + std::chrono::seconds(j->value("expires_in", 1800));

		spdlog::info("Twitch: login required, code {} at {}", userCode, uri);
		ShowInGame("TDL: Twitch login\nOpen twitch.tv/activate and enter code:\n" + userCode +
				   "\n\n(a browser window has been opened)");
		ShellExecuteW(nullptr, L"open", Widen(uri).c_str(), nullptr, nullptr, SW_SHOWNORMAL);

		while (Clock::now() < deadline) {
			SleepFor(std::chrono::seconds(interval));
			const auto r = PostForm("https://id.twitch.tv/oauth2/token",
				"client_id="s + kClientId + "&scopes=" + UrlEncode(kScopes) + "&device_code=" + UrlEncode(deviceCode) +
					"&grant_type=urn:ietf:params:oauth:grant-type:device_code");
			if (r.status == 200) {
				return AcceptTokens(r);
			}
			const auto e = ParseJson(r.body);
			const auto msg = e ? e->value("message", "") : std::string{};
			if (msg == "authorization_pending" || r.status == 0) {
				continue;
			}
			if (msg == "slow_down") {
				interval += 5;
				continue;
			}
			spdlog::warn("Twitch: device login failed ({}): {}", r.status, r.body);
			return Auth::kInvalid;
		}
		spdlog::warn("Twitch: login code expired");
		return Auth::kInvalid;
	}

	// Ensures g_access/g_userId are valid; logs in interactively if needed.
	Auth EnsureAuth()
	{
		if (MockMode()) {
			g_userId = "12345";
			return Auth::kOk;
		}
		if (!g_access.empty()) {
			if (const auto v = Validate(); v != Auth::kInvalid) {
				return v;
			}
		}
		auto a = Refresh();
		if (a == Auth::kInvalid) {
			a = DeviceLogin();
		}
		return a == Auth::kOk ? Validate() : a;
	}

	// ---------------------------------------------------------------- event -> action

	std::mt19937 g_rng{ std::random_device{}() };

	// Skyrim shows Papyrus strings in the system ANSI code page (the mod's own .psc files are cp1251),
	// while the INI and Twitch names are UTF-8.
	std::string ToGameText(const std::string& utf8)
	{
		const auto w = Widen(utf8);
		const int n = WideCharToMultiByte(CP_ACP, 0, w.data(), static_cast<int>(w.size()), nullptr, 0, nullptr, nullptr);
		std::string out(static_cast<size_t>(n), '\0');
		WideCharToMultiByte(CP_ACP, 0, w.data(), static_cast<int>(w.size()), out.data(), n, nullptr, nullptr);
		return out;
	}

	// Single pass, so a viewer named "{trigger}" is not expanded again.
	std::string Expand(const std::string& tmpl, const std::string& user, const std::string& trigger)
	{
		std::string out;
		for (size_t i = 0; i < tmpl.size();) {
			if (tmpl.compare(i, 6, "{user}") == 0) {
				out += user;
				i += 6;
			} else if (tmpl.compare(i, 9, "{trigger}") == 0) {
				out += trigger;
				i += 9;
			} else {
				out += tmpl[i++];
			}
		}
		return out;
	}

	// [Messages] ACTION={user} ... describes what happened; falls back to "viewer: trigger".
	std::string BuildNotice(const std::string& line, const std::string& who, const std::string& trigger)
	{
		if (IniValue("twitch", "Notify") == "0") {
			return {};
		}
		// line is "ACTION|SRC", "FORCE|ACTION|N" or "FORCE1|ACTION" (may be malformed: it comes from the INI)
		auto action = line.substr(0, line.find('|'));
		if (action == "FORCE" || action == "FORCE1") {
			const auto bar = line.find('|');
			const auto rest = bar == std::string::npos ? std::string{} : line.substr(bar + 1);
			action = rest.substr(0, rest.find('|'));
		}
		const auto name = who.empty() ? IniValue("twitch", "PollName") : who;

		const auto tmpl = IniValue("messages", action);
		const auto text = !tmpl.empty() ? Expand(tmpl, name, trigger) : name.empty() ? trigger : name + ": " + trigger;
		return ToGameText(text);  // shortcut: chars outside the ANSI code page (emoji in reward titles) become '?'
	}

	// Value is "ACTION", "A,B,C" (random pick, used for difficulty tiers) or a raw pipe line ("FORCE|ACTION|5").
	// who: viewer name (empty for polls); trigger: what they used, in the streamer's own words (reward title, "500 bits", "!cmd").
	void Submit(const std::string& value, int source, const std::string& who, const std::string& trigger)
	{
		std::vector<std::string> options;
		for (size_t pos = 0; pos <= value.size();) {
			const auto comma = std::min(value.find(',', pos), value.size());
			if (auto opt = Trim(value.substr(pos, comma - pos)); !opt.empty()) {
				options.push_back(std::move(opt));
			}
			pos = comma + 1;
		}
		if (options.empty()) {
			spdlog::info("Twitch: {} by {} -> no mapping", trigger, who);
			return;
		}
		const auto& action = options[std::uniform_int_distribution<size_t>(0, options.size() - 1)(g_rng)];
		const auto line = action.find('|') == std::string::npos ? action + "|" + std::to_string(source) : action;
		spdlog::info("Twitch: {} by {} -> {}", trigger, who, line);

		TDL_SubmitLine(line, BuildNotice(line, who, trigger));
	}

	std::string BitsMapping(int bits)
	{
		// Largest threshold not above the cheered amount wins.
		const auto& ini = Ini();
		const auto s = ini.find("bits");
		if (s == ini.end()) {
			return {};
		}
		int best = -1;
		std::string value;
		for (const auto& [k, v] : s->second) {
			int threshold = 0;
			try {
				threshold = std::stoi(k);
			} catch (...) {
				continue;
			}
			if (threshold <= bits && threshold > best) {
				best = threshold;
				value = v;
			}
		}
		return value;
	}

	// Twitch sends null (not a missing key) e.g. for anonymous cheers; json::value() would throw on that.
	std::string Str(const json& j, const char* key, const char* fallback)
	{
		const auto it = j.find(key);
		return it != j.end() && it->is_string() ? it->get<std::string>() : fallback;
	}

	bool IsPrivileged(const json& ev)
	{
		for (const auto& b : ev.value("badges", json::array())) {
			const auto id = b.value("set_id", "");
			if (id == "broadcaster" || id == "moderator") {
				return true;
			}
		}
		return false;
	}

	void HandleEvent(const std::string& type, const json& ev)
	{
		if (type == "channel.channel_points_custom_reward_redemption.add") {
			const auto title = ev.at("reward").value("title", "");
			Submit(IniValue("rewards", title), kSourcePoints, Str(ev, "user_name", "?"), title);
		} else if (type == "channel.cheer") {
			const int bits = ev.value("bits", 0);
			Submit(BitsMapping(bits), kSourceBits, Str(ev, "user_name", "Anonymous"), std::to_string(bits) + " bits");
		} else if (type == "channel.chat.message") {
			const auto text = Trim(ev.at("message").value("text", ""));
			if (text.empty() || text[0] != '!') {
				return;
			}
			if (IniValue("twitch", "ChatAllowEveryone") != "1" && !IsPrivileged(ev)) {
				return;
			}
			const auto cmd = LowerAscii(text.substr(0, text.find(' ')));
			const auto value = IniValue("chat", cmd);
			if (!value.empty()) {
				Submit(value, kSourcePoints, Str(ev, "chatter_user_name", "?"), cmd);
			}
		} else if (type == "channel.poll.end") {
			if (ev.value("status", "") != "completed") {
				return;
			}
			const json* winner = nullptr;
			const auto choices = ev.value("choices", json::array());  // keep alive: winner points into it
			for (const auto& c : choices) {
				if (!winner || c.value("votes", 0) > winner->value("votes", 0)) {
					winner = &c;
				}
			}
			if (winner) {
				const auto title = winner->value("title", "");
				Submit(IniValue("poll", title), kSourceVote, "", "Poll: " + title);
			}
		}
	}

	// ---------------------------------------------------------------- EventSub subscriptions

	bool SubscribeAll(const std::string& sessionId)
	{
		const json broadcaster = { { "broadcaster_user_id", g_userId } };
		const std::pair<const char*, json> subs[] = {
			{ "channel.channel_points_custom_reward_redemption.add", broadcaster },
			{ "channel.cheer", broadcaster },
			{ "channel.poll.end", broadcaster },
			{ "channel.chat.message", { { "broadcaster_user_id", g_userId }, { "user_id", g_userId } } },
		};

		const auto url = MockMode() ? "http://127.0.0.1:8080/eventsub/subscriptions"s :
		                              "https://api.twitch.tv/helix/eventsub/subscriptions"s;
		const auto headers = "Authorization: Bearer " + g_access + "\r\nClient-Id: " + kClientId +
		                     "\r\nContent-Type: application/json\r\n";

		int ok = 0;
		for (const auto& [type, condition] : subs) {
			const json body = { { "type", type }, { "version", "1" }, { "condition", condition },
				{ "transport", { { "method", "websocket" }, { "session_id", sessionId } } } };
			const auto r = Http("POST", url, body.dump(), headers);
			if (r.status == 202) {
				ok++;
			} else {
				// e.g. 403 for channel points/bits on channels without Affiliate: the rest still works
				spdlog::warn("Twitch: subscribe {} failed ({}): {}", type, r.status, r.body);
			}
		}
		spdlog::info("Twitch: {} of {} subscriptions active", ok, std::size(subs));
		return ok > 0;
	}

	// ---------------------------------------------------------------- WebSocket

	struct Ws
	{
		HINTERNET con = nullptr;
		HINTERNET ws = nullptr;
	};

	// We ask for 30 s keepalives (kEventSubUrl), so a silent socket for longer than this is dead.
	// A receive timeout instead of closing the handle from another thread: WinHTTP forbids that for synchronous calls.
	constexpr int kReceiveTimeoutMs = 45'000;

	Ws WsConnect(const std::string& url)
	{
		Ws w;
		const auto u = ParseUrl(url);
		if (!u) {
			return w;
		}
		w.con = WinHttpConnect(g_session, u->host.c_str(), u->port, 0);
		HINTERNET req = w.con ? WinHttpOpenRequest(w.con, L"GET", u->path.c_str(), nullptr, WINHTTP_NO_REFERER,
									WINHTTP_DEFAULT_ACCEPT_TYPES, u->secure ? WINHTTP_FLAG_SECURE : 0) :
								nullptr;
		if (req && WinHttpSetTimeouts(req, 0, 60'000, 30'000, kReceiveTimeoutMs) &&
			WinHttpSetOption(req, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, nullptr, 0) &&
			WinHttpSendRequest(req, WINHTTP_NO_ADDITIONAL_HEADERS, 0, nullptr, 0, 0, 0) &&
			WinHttpReceiveResponse(req, nullptr)) {
			w.ws = WinHttpWebSocketCompleteUpgrade(req, 0);
		}
		if (!w.ws) {
			spdlog::warn("Twitch: WebSocket connect to {} failed: {}", url, GetLastError());
		}
		if (req) {
			WinHttpCloseHandle(req);
		}
		if (!w.ws && w.con) {
			WinHttpCloseHandle(w.con);
			w.con = nullptr;
		}
		return w;
	}

	void WsClose(Ws& w)
	{
		if (w.ws) {
			WinHttpCloseHandle(w.ws);
		}
		if (w.con) {
			WinHttpCloseHandle(w.con);
		}
		w = {};
	}

	bool WsRead(HINTERNET ws, std::string& out)
	{
		out.clear();
		char buf[8192];
		for (;;) {
			DWORD read = 0;
			WINHTTP_WEB_SOCKET_BUFFER_TYPE type{};
			if (const auto err = WinHttpWebSocketReceive(ws, buf, sizeof(buf), &read, &type); err != NO_ERROR) {
				spdlog::warn("Twitch: WebSocket receive ended: {}", err);  // ERROR_WINHTTP_TIMEOUT (12002) = no keepalive
				return false;
			}
			if (type == WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE) {
				return false;
			}
			out.append(buf, read);
			if (out.size() > (1u << 20)) {
				return false;  // EventSub messages are small; refuse unbounded growth
			}
			if (type == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE || type == WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE) {
				return true;
			}
		}
	}

	std::string MessageType(const std::optional<json>& j)
	{
		return j && j->contains("metadata") ? j->at("metadata").value("message_type", "") : std::string{};
	}

	// Runs one EventSub session chain (including server-requested reconnects). Returns when the connection is lost.
	void RunSession(Ws ws)
	{
		bool subscribed = false;  // subscriptions survive session_reconnect
		std::deque<std::string> seenIds;
		std::string msg;

		while (WsRead(ws.ws, msg)) {
			const auto j = ParseJson(msg);
			if (MessageType(j).empty()) {
				continue;
			}
			try {
				const auto& meta = j->at("metadata");
				const auto& payload = j->at("payload");
				const auto type = meta.value("message_type", "");

				if (type == "session_welcome") {
					if (!subscribed) {
						if (!SubscribeAll(payload.at("session").value("id", ""))) {
							break;
						}
						subscribed = true;
					}
				} else if (type == "notification") {
					const auto id = meta.value("message_id", "");
					if (std::find(seenIds.begin(), seenIds.end(), id) != seenIds.end()) {
						continue;  // EventSub may redeliver
					}
					seenIds.push_back(id);
					if (seenIds.size() > 200) {
						seenIds.pop_front();
					}
					HandleEvent(meta.value("subscription_type", ""), payload.at("event"));
				} else if (type == "session_reconnect") {
					// Twitch keeps using the old socket until the new one got its welcome: switch only after that.
					auto next = WsConnect(payload.at("session").value("reconnect_url", ""));
					std::string first;
					if (!next.ws || !WsRead(next.ws, first) || MessageType(ParseJson(first)) != "session_welcome") {
						spdlog::warn("Twitch: reconnect failed, starting a new session");
						WsClose(next);
						break;
					}
					WsClose(ws);
					ws = next;
					spdlog::info("Twitch: reconnected");
				} else if (type == "revocation") {
					spdlog::warn("Twitch: subscription revoked: {}", payload.at("subscription").dump());
					if (payload.at("subscription").value("status", "") == "authorization_revoked") {
						g_access.clear();
						break;
					}
				}

				// Twitch requires hourly token validation for long-lived sessions.
				if (!MockMode() && Clock::now() - g_lastValidate > std::chrono::hours(1) && Validate() == Auth::kInvalid) {
					g_access.clear();
					break;
				}
			} catch (const json::exception& e) {
				spdlog::warn("Twitch: bad message ({}): {}", e.what(), msg);
			}
		}
		WsClose(ws);
	}

	void TwitchThread()
	{
		CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);  // ShellExecute requirement
		g_session = WinHttpOpen(L"TDL_StreamPlugin", WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY, WINHTTP_NO_PROXY_NAME,
			WINHTTP_NO_PROXY_BYPASS, 0);
		if (!g_session) {
			spdlog::error("Twitch: WinHttpOpen failed: {}", GetLastError());
			return;
		}

		int backoff = 1;
		for (;;) {
			const auto auth = EnsureAuth();
			if (auth == Auth::kInvalid) {
				// Login was not completed; don't keep popping codes at the player. Restart the game to retry.
				spdlog::warn("Twitch: not logged in, integration stopped for this session");
				ShowInGame("TDL: Twitch login was not completed.\nRestart the game to try again.");
				return;
			}
			if (auth == Auth::kOk) {
				const auto url = MockMode() ? IniValue("twitch", "MockUrl") : std::string{ kEventSubUrl };
				if (auto ws = WsConnect(url.empty() ? "ws://127.0.0.1:8080/ws" : url); ws.ws) {
					const auto started = Clock::now();
					RunSession(ws);
					if (Clock::now() - started > std::chrono::minutes(1)) {
						backoff = 1;
					}
				}
			}
			SleepFor(std::chrono::seconds(backoff));
			backoff = std::min(backoff * 2, 60);
		}
	}

	std::atomic_bool g_started{ false };
}

void TDL_StartTwitch()
{
	if (IniValue("twitch", "Enabled") == "0") {
		spdlog::info("Twitch: disabled in TDL_Twitch.ini");
		return;
	}
	if (g_started.exchange(true)) {
		return;
	}
	spdlog::info("Twitch: starting");
	std::thread(TwitchThread).detach();  // detached like the scheduler: no shutdown hook in SKSE
}
