// Local loopback HTTP server for the OBS overlay and settings editor.
#include "TDL_Overlay.h"
#include "TDL_PipeServer.h"

#include <RE/M/Misc.h>
#include <RE/S/Setting.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <Windows.h>
#include <bcrypt.h>
#include <objbase.h>
#include <shellapi.h>
#include <spdlog/spdlog.h>
#include <nlohmann/json.hpp>

#include <algorithm>
#include <atomic>
#include <cassert>
#include <charconv>
#include <chrono>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

namespace
{
	using json = nlohmann::json;
	constexpr size_t kMaxBody = 256 * 1024;
	std::atomic_bool g_started{ false };
	std::atomic_int g_listeningPort{ 0 };
	std::mutex g_saveMutex;
	bool g_backedUp = false;
	std::string g_token;

	std::filesystem::path PluginDir() { return std::filesystem::current_path() / "Data" / "SKSE" / "Plugins"; }
	std::filesystem::path IniPath() { return PluginDir() / "TDL_Twitch.ini"; }
	std::string ReadFile(const std::filesystem::path& p)
	{
		std::ifstream f(p, std::ios::binary);
		std::ostringstream ss;
		ss << f.rdbuf();
		return ss.str();
	}
	std::string WithoutBom(std::string file)
	{
		if (file.starts_with("\xEF\xBB\xBF")) file.erase(0, 3);
		return file;
	}
	std::string Trim(std::string s)
	{
		const auto first = s.find_first_not_of(" \t");
		if (first == std::string::npos) return {};
		return s.substr(first, s.find_last_not_of(" \t") - first + 1);
	}
	std::string Lower(std::string s)
	{
		for (auto& c : s) if (c >= 'A' && c <= 'Z') c = static_cast<char>(c + ('a' - 'A'));
		return s;
	}
	bool HasNewline(const std::string& s) { return s.find_first_of("\r\n") != std::string::npos; }
	bool IsSection(const std::string& line, std::string& name)
	{
		const auto s = Trim(line);
		if (s.size() < 3 || s.front() != '[' || s.back() != ']') return false;
		name = s.substr(1, s.size() - 2);
		return true;
	}
	bool IsEntry(const std::string& line, std::string& key, std::string& value)
	{
		const auto s = Trim(line);
		if (s.empty() || s[0] == ';' || s[0] == '#' || s[0] == '[') return false;
		const auto eq = line.find('=');
		if (eq == std::string::npos) return false;
		key = Trim(line.substr(0, eq));
		value = Trim(line.substr(eq + 1));
		return !key.empty();
	}
	std::vector<std::string> Lines(const std::string& file)
	{
		std::vector<std::string> lines;
		for (size_t pos = 0; pos < file.size();) {
			const auto end = file.find('\n', pos);
			lines.push_back(file.substr(pos, end == std::string::npos ? end : end - pos + 1));
			if (end == std::string::npos) break;
			pos = end + 1;
		}
		return lines;
	}
	std::string Content(const std::string& line)
	{
		auto end = line.size();
		if (end && line[end - 1] == '\n') --end;
		if (end && line[end - 1] == '\r') --end;
		return line.substr(0, end);
	}
	std::string Ending(const std::string& line)
	{
		return line.substr(Content(line).size());
	}
	json Sections(const std::string& file)
	{
		json sections = json::array();
		std::map<std::string, size_t> positions;
		std::map<std::string, std::set<std::string>> keys;
		size_t current = 0;
		for (const auto& line : Lines(file)) {
			std::string name, key, value;
			const auto raw = Content(line);
			if (IsSection(raw, name)) {
				const auto normalized = Lower(name);
				if (!positions.contains(normalized)) {
					current = sections.size();
					positions.emplace(normalized, current);
					sections.push_back({ { "name", name }, { "entries", json::array() } });
				} else current = positions.at(normalized);
			} else if (!sections.empty() && IsEntry(raw, key, value) && keys[Lower(sections[current]["name"].get<std::string>())].insert(Lower(key)).second)
				sections[current]["entries"].push_back({ { "key", key }, { "value", value } });
		}
		return sections;
	}
	// ASVS 2.2.1, 2.2.2: validate the complete posted shape before modifying the file.
	bool Validate(const json& body, std::string& error)
	{
		if (!body.is_object() || !body.contains("sections") || !body["sections"].is_array()) { error = "sections must be an array"; return false; }
		std::set<std::string> names;
		for (const auto& section : body["sections"]) {
			if (!section.is_object() || !section.contains("name") || !section["name"].is_string() || !section.contains("entries") || !section["entries"].is_array()) { error = "invalid section"; return false; }
			const auto name = section["name"].get<std::string>();
			if (name.empty() || HasNewline(name) || name.find(']') != std::string::npos || !names.insert(Lower(name)).second) { error = "invalid or duplicate section name"; return false; }
			std::set<std::string> keys;
			for (const auto& entry : section["entries"]) {
				if (!entry.is_object() || !entry.contains("key") || !entry["key"].is_string() || !entry.contains("value") || !entry["value"].is_string()) { error = "invalid entry"; return false; }
				const auto key = entry["key"].get<std::string>();
				const auto value = entry["value"].get<std::string>();
				const auto trimmed = Trim(key);
				if (trimmed.empty() || HasNewline(key) || HasNewline(value) || key.find('=') != std::string::npos || trimmed[0] == ';' || trimmed[0] == '[' || trimmed[0] == '#' || !keys.insert(Lower(trimmed)).second) { error = "invalid or duplicate key/value"; return false; }
			}
		}
		return true;
	}
	std::string Merge(const std::string& file, const json& requested)
	{
		const auto newline = file.find("\r\n") != std::string::npos ? "\r\n" : "\n";
		const auto lines = Lines(file);
		std::map<std::string, const json*> wanted;
		for (const auto& section : requested["sections"]) wanted.emplace(Lower(section["name"].get<std::string>()), &section);
		std::set<std::string> found;
		std::string out;
		for (size_t begin = 0; begin < lines.size();) {
			std::string name;
			const bool section = IsSection(Content(lines[begin]), name);
			size_t end = begin + 1;
			while (end < lines.size()) {
				std::string next;
				if (IsSection(Content(lines[end]), next)) break;
				++end;
			}
			const auto it = section ? wanted.find(Lower(name)) : wanted.end();
			if (it == wanted.end()) {
				for (size_t i = begin; i < end; ++i) out += lines[i];
			} else if (!found.insert(Lower(name)).second) {
				for (size_t i = begin; i < end; ++i) {
					std::string key, value;
					if (i == begin || !IsEntry(Content(lines[i]), key, value)) out += lines[i];
				}
			} else {
				const auto& entries = (*it->second)["entries"];
				std::set<std::string> used;
				size_t lastKey = begin;
				for (size_t i = begin + 1; i < end; ++i) {
					std::string key, value;
					if (IsEntry(Content(lines[i]), key, value)) lastKey = i;
				}
				for (size_t i = begin; i < end; ++i) {
					std::string key, value;
					const auto raw = Content(lines[i]);
					if (i != begin && IsEntry(raw, key, value)) {
						const auto normalized = Lower(key);
						for (const auto& entry : entries) {
							if (Lower(Trim(entry["key"].get<std::string>())) == normalized) {
								// Inline semicolons are value text in TDL_LoadIni, not comments.
								if (used.insert(normalized).second) out += raw.substr(0, raw.find('=') + 1) + entry["value"].get<std::string>() + Ending(lines[i]);
								break;
							}
						}
					} else out += lines[i];
					if (i == lastKey) {
						for (const auto& entry : entries) {
							const auto newKey = entry["key"].get<std::string>();
							if (!used.contains(Lower(Trim(newKey)))) {
								if (!out.empty() && out.back() != '\n') out += newline;
								out += newKey + "=" + entry["value"].get<std::string>() + newline;
							}
						}
					}
				}
			}
			begin = end;
		}
		for (const auto& section : requested["sections"]) {
			const auto name = section["name"].get<std::string>();
			if (found.contains(Lower(name))) continue;
			if (!out.empty() && out.back() != '\n') out += newline;
			out += "[" + name + "]" + newline;
			for (const auto& entry : section["entries"]) out += entry["key"].get<std::string>() + "=" + entry["value"].get<std::string>() + newline;
		}
		return out;
	}
	bool Save(const json& body, std::string& error)
	{
		std::lock_guard lock(g_saveMutex); // ASVS 15.4.1: serialize backup and replacement.
		const auto path = IniPath();
		std::error_code ec;
		if (!std::filesystem::exists(path, ec) || ec) { error = "INI file unavailable"; return false; }
		const auto original = WithoutBom(ReadFile(path));
		const auto merged = Merge(original, body);
		const auto temp = path.wstring() + L".tmp";
		{
			std::ofstream f(std::filesystem::path(temp), std::ios::binary | std::ios::trunc);
			f.write(merged.data(), static_cast<std::streamsize>(merged.size()));
			f.flush();
			if (!f) { error = "cannot write temporary INI"; return false; }
		}
		if (!g_backedUp) {
			// FALSE overwrites a prior session's .bak; mark backed up only after the copy succeeds.
			if (!CopyFileW(path.c_str(), (path.wstring() + L".bak").c_str(), FALSE)) { DeleteFileW(temp.c_str()); error = "cannot back up INI"; return false; }
			g_backedUp = true;
		}
		if (!MoveFileExW(temp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) { DeleteFileW(temp.c_str()); error = "cannot replace INI"; return false; }
		return true;
	}
	bool AllowedHostOrigin(const std::string& host, const std::string& origin, int port)
	{
		const auto suffix = ":" + std::to_string(port);
		const auto local = host == "127.0.0.1" + suffix || host == "localhost" + suffix;
		return local && (origin.empty() || origin == "http://127.0.0.1" + suffix || origin == "http://localhost" + suffix);
	}
	std::string SoundFile()
	{
		const auto state = json::parse(TDL_GetStateJson(), nullptr, false);
		if (!state.is_object() || !state.value("sound", false)) return {};
		const auto name = state.value("soundFile", std::string{});
		if (name.empty() || name.size() > 128 || !std::all_of(name.begin(), name.end(), [](unsigned char c) { return std::isalnum(c) || c == '_' || c == '-' || c == '.'; })) return {};
		const auto ext = std::filesystem::path(name).extension().string();
		return ext == ".mp3" || ext == ".wav" || ext == ".ogg" ? name : std::string{};
	}
	void SendAll(SOCKET s, const std::string& data)
	{
		for (size_t sent = 0; sent < data.size();) {
			const int n = send(s, data.data() + sent, static_cast<int>(data.size() - sent), 0);
			if (n <= 0) return;
			sent += static_cast<size_t>(n);
		}
	}
	void Respond(SOCKET s, const char* status, const char* type, const std::string& body, bool cors = false)
	{
		// ASVS 3.5.1: settings and API never opt into cross-origin access.
		SendAll(s, std::string("HTTP/1.1 ") + status + "\r\nContent-Type: " + type +
			"\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n" +
			(cors ? "Access-Control-Allow-Origin: *\r\n" : "") +
			"Connection: close\r\nContent-Length: " + std::to_string(body.size()) + "\r\n\r\n" + body);
	}
	struct Request { std::string method, path, body; std::map<std::string, std::string> headers; };
	bool ReadRequest(SOCKET c, Request& request, bool& expired)
	{
		const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(5);
		const auto receive = [&](char* data, int length) {
			const auto remaining = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - std::chrono::steady_clock::now()).count();
			if (remaining <= 0) { expired = true; return -1; }
			const DWORD timeout = static_cast<DWORD>(remaining);
			setsockopt(c, SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char*>(&timeout), sizeof(timeout));
			const int n = recv(c, data, length, 0);
			if (std::chrono::steady_clock::now() >= deadline) expired = true;
			return n;
		};
		std::string input;
		char buf[4096];
		size_t headerEnd = std::string::npos;
		while ((headerEnd = input.find("\r\n\r\n")) == std::string::npos) {
			const int n = receive(buf, sizeof(buf));
			if (expired || n <= 0 || input.size() + n > 16 * 1024) return false;
			input.append(buf, n);
		}
		std::istringstream stream(input.substr(0, headerEnd));
		std::string first, version;
		if (!(stream >> request.method >> request.path >> version) || version != "HTTP/1.1") return false;
		std::string line;
		std::getline(stream, line);
		while (std::getline(stream, line)) {
			if (!line.empty() && line.back() == '\r') line.pop_back();
			const auto colon = line.find(':');
			if (colon == std::string::npos || colon == 0) return false;
			const auto key = Lower(line.substr(0, colon));
			if (!request.headers.emplace(key, Trim(line.substr(colon + 1))).second) return false;
		}
		if (request.headers.contains("transfer-encoding")) return false;
		size_t size = 0;
		if (auto it = request.headers.find("content-length"); it != request.headers.end()) {
			const auto& s = it->second;
			const auto parsed = std::from_chars(s.data(), s.data() + s.size(), size);
			if (parsed.ec != std::errc{} || parsed.ptr != s.data() + s.size() || size > kMaxBody) return false;
		} else if (request.method == "POST") return false;
		request.body = input.substr(headerEnd + 4);
		if (request.body.size() > size) return false;
		while (request.body.size() < size) {
			const int n = receive(buf, static_cast<int>(std::min(sizeof(buf), size - request.body.size())));
			if (expired || n <= 0) return false;
			request.body.append(buf, n);
		}
		if (const auto query = request.path.find('?'); query != std::string::npos) request.path.resize(query);
		return true;
	}
	void Handle(SOCKET c, int port)
	{
		DWORD timeout = 2000;
		setsockopt(c, SOL_SOCKET, SO_SNDTIMEO, reinterpret_cast<const char*>(&timeout), sizeof(timeout));
		Request r;
		bool expired = false;
		if (!ReadRequest(c, r, expired)) { if (!expired) Respond(c, "400 Bad Request", "text/plain; charset=utf-8", "bad request"); return; }
		if (r.method == "OPTIONS") { Respond(c, "405 Method Not Allowed", "text/plain; charset=utf-8", "method not allowed"); return; }
		const auto api = r.path.starts_with("/api/");
		if (api && (!AllowedHostOrigin(r.headers["host"], r.headers["origin"], port) || r.headers["x-tdl-token"] != g_token)) {
			Respond(c, "403 Forbidden", "application/json; charset=utf-8", R"({"ok":false,"error":"forbidden"})"); return;
		}
		if (r.path == "/api/config") {
			if (r.method == "GET") {
				std::lock_guard lock(g_saveMutex);
				const auto* language = RE::GetINISetting("sLanguage:General");
				const auto lang = language && language->GetString() && Lower(language->GetString()) == "russian" ? "ru" : "en";
				Respond(c, "200 OK", "application/json; charset=utf-8", json{ { "version", 1 }, { "lang", lang }, { "port", port }, { "sections", Sections(WithoutBom(ReadFile(IniPath()))) } }.dump());
			} else if (r.method == "POST") {
				const auto contentType = Lower(r.headers["content-type"]);
				if (contentType != "application/json" && contentType != "application/json; charset=utf-8") { Respond(c, "400 Bad Request", "application/json; charset=utf-8", R"({"ok":false,"error":"Content-Type must be application/json"})"); return; }
				const auto body = json::parse(r.body, nullptr, false);
				std::string error;
				if (body.is_discarded() || !Validate(body, error)) { Respond(c, "400 Bad Request", "application/json; charset=utf-8", json{ { "ok", false }, { "error", error.empty() ? "invalid JSON" : error } }.dump()); return; }
				if (!Save(body, error)) { Respond(c, "500 Internal Server Error", "application/json; charset=utf-8", json{ { "ok", false }, { "error", error } }.dump()); return; }
				Respond(c, "200 OK", "application/json; charset=utf-8", R"({"ok":true})");
			} else Respond(c, "405 Method Not Allowed", "text/plain; charset=utf-8", "method not allowed");
		} else if (r.method != "GET") Respond(c, "405 Method Not Allowed", "text/plain; charset=utf-8", "GET only");
		else if (r.path == "/state") {
			const auto ini = TDL_LoadIni(IniPath());
			const auto section = ini.find("overlay");
			const bool disabled = section != ini.end() && section->second.contains("enabled") && section->second.at("enabled") == "0";
			Respond(c, "200 OK", "application/json; charset=utf-8", disabled ? R"({"enabled":false,"paused":false,"top":[],"showTop":false,"queue":[],"recent":[],"showRecent":false,"sound":false,"vote":null})" : TDL_GetStateJson(), true);
		}
		else if (r.path == "/sound") {
			const auto name = SoundFile();
			const auto file = PluginDir() / name;
			std::error_code ec;
			const auto size = name.empty() ? uintmax_t{} : std::filesystem::file_size(file, ec);
			if (name.empty() || ec || size > 10 * 1024 * 1024) { Respond(c, "404 Not Found", "text/plain; charset=utf-8", "sound unavailable", true); return; }
			const auto body = ReadFile(file);
			if (body.empty()) { Respond(c, "404 Not Found", "text/plain; charset=utf-8", "sound unavailable", true); return; }
			const auto ext = std::filesystem::path(name).extension().string();
			Respond(c, "200 OK", ext == ".mp3" ? "audio/mpeg" : ext == ".wav" ? "audio/wav" : "audio/ogg", body, true);
		} else if (r.path == "/settings") {
			auto html = ReadFile(PluginDir() / "TDL_Settings.html");
			if (html.empty()) { Respond(c, "404 Not Found", "text/plain; charset=utf-8", "TDL_Settings.html not found"); return; }
			const std::string marker = "{{TDL_TOKEN}}";
			for (size_t at = 0; (at = html.find(marker, at)) != std::string::npos; at += g_token.size()) html.replace(at, marker.size(), g_token);
			Respond(c, "200 OK", "text/html; charset=utf-8", html);
		} else if (r.path == "/" || r.path == "/overlay") {
			const auto html = ReadFile(PluginDir() / "TDL_Overlay.html");
			Respond(c, html.empty() ? "404 Not Found" : "200 OK", "text/html; charset=utf-8", html.empty() ? "TDL_Overlay.html not found" : html);
		} else Respond(c, "404 Not Found", "text/plain; charset=utf-8", "not found");
	}
#ifndef NDEBUG
	void SelfCheck()
	{
		const auto before = std::string("; head\r\n[A]\r\n; keep\r\nx = old\r\ny=gone\r\n; tail\r\n[B]\r\nz=stay\r\n");
		const json edit = { { "sections", json::array({ { { "name", "A" }, { "entries", json::array({ { { "key", "x" }, { "value", "new" } }, { { "key", "n" }, { "value", "added" } } }) } }, { { "name", "C" }, { "entries", json::array({ { { "key", "q" }, { "value", "v" } } }) } } }) } };
		const auto after = Merge(before, edit);
		assert(after.find("x =new\r\n") != std::string::npos);
		assert(after.find("y=gone") == std::string::npos);
		assert(after.find("n=added\r\n") != std::string::npos);
		assert(after.find("[C]\r\nq=v\r\n") != std::string::npos);
		assert(after.find("; head\r\n") != std::string::npos && after.find("; keep\r\n") != std::string::npos && after.find("; tail\r\n") != std::string::npos);
		assert(after.find("[B]\r\nz=stay\r\n") != std::string::npos);
		assert(after.find("n=added\r\n") < after.find("; tail\r\n"));
		assert(after.find("; tail\r\n") < after.find("[B]\r\n"));
		const auto duplicate = std::string("[A]\r\nx=first\r\n; first\r\n[a]\r\nx=second\r\ny=later\r\n; second\r\n");
		const auto combined = Sections(duplicate);
		assert(combined.size() == 1 && combined[0]["entries"].size() == 2);
		assert(combined[0]["entries"][0]["value"] == "first" && combined[0]["entries"][1]["value"] == "later");
		const auto mergedDuplicate = Merge(duplicate, json{ { "sections", combined } });
		assert(mergedDuplicate.find("x=first\r\ny=later\r\n") != std::string::npos);
		assert(mergedDuplicate.find("x=second") == std::string::npos && mergedDuplicate.find("[a]\r\n; second\r\n") != std::string::npos);
		assert(AllowedHostOrigin("127.0.0.1:8645", "http://localhost:8645", 8645));
		assert(AllowedHostOrigin("localhost:8645", "", 8645));
		assert(!AllowedHostOrigin("evil.test:8645", "", 8645));
		assert(!AllowedHostOrigin("localhost:8645", "http://evil.test:8645", 8645));
		assert(!AllowedHostOrigin("localhost:8645.evil.test", "", 8645));
	}
#endif
	void ServerThread(int port)
	{
		WSADATA wsa{};
		if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) { spdlog::error("Overlay: WSAStartup failed"); return; }
		SOCKET ls = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
		sockaddr_in addr{};
		addr.sin_family = AF_INET;
		addr.sin_port = htons(static_cast<u_short>(port));
		addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
		if (ls == INVALID_SOCKET || bind(ls, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || listen(ls, 8) != 0) {
			spdlog::error("Overlay: cannot listen on 127.0.0.1:{} (error {})", port, WSAGetLastError());
			if (ls != INVALID_SOCKET) closesocket(ls);
			return;
		}
		// ASVS 11.5.1: 128 random bits per server session, never logged.
		unsigned char bytes[16];
		if (BCryptGenRandom(nullptr, bytes, sizeof(bytes), BCRYPT_USE_SYSTEM_PREFERRED_RNG) < 0) { spdlog::error("Settings: token generation failed"); closesocket(ls); return; }
		constexpr char hex[] = "0123456789abcdef";
		for (auto b : bytes) { g_token += hex[b >> 4]; g_token += hex[b & 15]; }
		g_listeningPort.store(port);
		spdlog::info("Overlay: http://127.0.0.1:{}/ (add as OBS Browser Source)", port);
		spdlog::info("Settings: http://127.0.0.1:{}/settings", port);
		for (;;) {
			SOCKET c = accept(ls, nullptr, nullptr);
			if (c == INVALID_SOCKET) continue;
			Handle(c, port);
			closesocket(c);
		}
	}
}

int TDL_OverlayPort()
{
	if (const int running = g_listeningPort.load(); running) return running;
	const auto ini = TDL_LoadIni(IniPath());
	const auto section = ini.find("overlay");
	if (section == ini.end()) return 8645;
	const auto it = section->second.find("port");
	if (it == section->second.end()) return 8645;
	int port = 0;
	const auto& p = it->second;
	const auto result = std::from_chars(p.data(), p.data() + p.size(), port);
	return result.ec == std::errc{} && result.ptr == p.data() + p.size() && port > 0 && port <= 65535 ? port : 8645;
}

bool TDL_OpenSettings()
{
	const int port = g_listeningPort.load();
	if (!port) return false;
	const auto url = L"http://127.0.0.1:" + std::to_wstring(port) + L"/settings";
	// ASVS 1.4.3: capture the URL by value so the detached thread owns its data.
	std::thread([url] {
		const HRESULT com = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
		ShellExecuteW(nullptr, L"open", url.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
		if (SUCCEEDED(com)) CoUninitialize();
	}).detach();
	return true;
}

void TDL_StartOverlay()
{
	if (g_started.exchange(true)) return;
#ifndef NDEBUG
	SelfCheck();
#endif
	std::thread(ServerThread, TDL_OverlayPort()).detach();
}
