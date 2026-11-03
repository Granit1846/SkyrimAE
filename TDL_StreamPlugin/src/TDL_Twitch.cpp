// src/TDL_Twitch.cpp
// Native Twitch integration: Device Code login (public client, no secret), EventSub over WebSocket,
// events mapped to TDL actions via TDL_Twitch.ini and queued through the existing scheduler.
#include "TDL_Twitch.h"
#include "TDL_PipeServer.h"
#include "TDL_Overlay.h"

// CommonLib headers must precede Windows.h (its macros break RE types)
#ifndef TDL_TWITCH_HARNESS
#include <RE/M/Misc.h>
#include <RE/P/PlayerCharacter.h>
#include <SKSE/SKSE.h>
#endif

#include <Windows.h>
#include <objbase.h>
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
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <fstream>
#include <filesystem>
#include <functional>
#include <cmath>
#include <mutex>
#include <numeric>
#include <optional>
#include <random>
#include <ctime>
#include <cstdlib>
#include <stdexcept>
#include <unordered_set>
#include <string>
#include <thread>
#include <unordered_map>

using json = nlohmann::json;
using namespace std::literals;

namespace
{
	constexpr const char* kClientId = "ki8umjlmg23b9hiuq2o20usjvjpayn";
	// Changing this list makes existing users log in again (Validate checks the token has all of them).
	constexpr const char* kScopes =
		"channel:read:redemptions channel:manage:redemptions bits:read user:read:chat user:write:chat channel:read:polls channel:read:subscriptions channel:read:hype_train";
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
	std::atomic_bool g_paused{ false };
	std::atomic_bool g_pauseHold{ false };
	std::atomic_bool g_connected{ false };
	void CancelVote();

	void SetPaused(bool paused)
	{
		TDL_SetTwitchPauseState(paused, g_pauseHold.load());
		if (g_paused.exchange(paused) != paused) {
			TDL_WakeScheduler();
			TDL_Notify(paused ? "TDL paused" : "TDL resumed");
			if (paused) CancelVote();
		}
	}

	// Re-read on change so the Configurator can edit mappings while the game runs.
	// Read by the Twitch, outbox and scheduler (outcome hook) threads; callers hold g_cfgMtx.
	std::recursive_mutex g_cfgMtx;  // pause transition outcomes can read the INI during a reload

	const TDL_IniData& Ini()
	{
		std::error_code ec;
		const auto t = std::filesystem::last_write_time(IniPath(), ec);
		if (!ec && t != g_cfg.mtime) {
			g_cfg.ini = TDL_LoadIni(IniPath());
			g_cfg.mtime = t;
			const auto section = g_cfg.ini.find("twitch");
			const auto key = section == g_cfg.ini.end() ? nullptr : &section->second;
			// ASVS 2.2.1, 2.3.1: only "hold" changes the default cancel workflow.
			const bool hold = key && key->contains("pausemode") && LowerAscii(key->at("pausemode")) == "hold";
			TDL_SetTwitchPauseState(key && key->contains("paused") && key->at("paused") == "1", hold);
			g_pauseHold.store(hold);
			SetPaused(key && key->contains("paused") && key->at("paused") == "1");
			spdlog::info("Twitch: mapping loaded from '{}'", IniPath().string());
		}
		return g_cfg.ini;
	}

	std::string IniValue(const char* section, const std::string& key, const char* fallback = "")
	{
		std::lock_guard lk(g_cfgMtx);
		const auto& ini = Ini();
		const auto s = ini.find(section);
		if (s == ini.end()) {
			return fallback;
		}
		const auto k = s->second.find(LowerAscii(Trim(key)));
		return k == s->second.end() ? std::string(fallback) : k->second;
	}

	bool MockMode() { return IniValue("twitch", "MockServer") == "1"; }

	int IniInt(const char* section, const char* key, int fallback)
	{
		const auto value = IniValue(section, key);
		int n = 0;
		const auto result = std::from_chars(value.data(), value.data() + value.size(), n);
		return result.ec == std::errc{} && result.ptr == value.data() + value.size() && n >= 0 ? n : fallback;
	}

	struct RaidPart { std::vector<std::string> actions; int minCount = 1, maxCount = 1, divisor = 0; bool random = false, counted = false, force1 = false; };
	struct RaidTier { int threshold; std::vector<std::vector<RaidPart>> groups; };
	using RaidActions = std::vector<std::pair<std::string, int>>;

	bool ParsePositive(std::string_view s, int& n)
	{
		const auto r = std::from_chars(s.data(), s.data() + s.size(), n);
		return r.ec == std::errc{} && r.ptr == s.data() + s.size() && n > 0;
	}

	std::optional<int> ParseTestRaidViewers(std::string_view s)
	{
		const bool negative = !s.empty() && s.front() == '-';
		if (!s.empty() && (s.front() == '-' || s.front() == '+')) s.remove_prefix(1);
		if (s.empty()) return std::nullopt;
		int viewers = 0;
		for (const char c : s) {
			if (c < '0' || c > '9') return std::nullopt;
			viewers = std::min(100000, viewers * 10 + (c - '0'));
		}
		return negative ? 1 : std::max(1, viewers);  // ASVS 2.2.1, 1.4.2: bound untrusted counts before raid scaling.
	}

	std::vector<std::string> SplitRaid(std::string_view s, char delimiter)
	{
		std::vector<std::string> out;
		size_t start = 0;
		int depth = 0;
		for (size_t i = 0; i <= s.size(); ++i) {
			if (i < s.size() && s[i] == '(') ++depth;
			else if (i < s.size() && s[i] == ')') --depth;
			if (depth < 0) return {};
			if (i == s.size() || (s[i] == delimiter && depth == 0)) {
				out.push_back(Trim(std::string(s.substr(start, i - start))));
				start = i + 1;
			}
		}
		return depth == 0 ? out : std::vector<std::string>{};
	}

	std::optional<RaidPart> ParseRaidPart(const std::string& value,
		const std::unordered_map<std::string, std::vector<std::string>>& pools)
	{
		RaidPart part;
		const auto token = value.starts_with("FORCE1|") ? value.substr(7) : value;
		part.force1 = token.size() != value.size();
		const auto close = token.starts_with("RANDOM(") ? token.find(')') : std::string::npos;
		part.random = close != std::string::npos;
		if (part.force1 && (part.random || token.find('|') != std::string::npos)) return std::nullopt;
		if (part.random) {
			const auto list = Trim(token.substr(7, close - 7));
			if (list.find(',') == std::string::npos) {
				if (const auto it = pools.find(LowerAscii(list)); it != pools.end()) part.actions = it->second;
				else if (list.find('_') != std::string::npos &&
					!list.empty() && std::isupper(static_cast<unsigned char>(list.front()))) part.actions = { list };
				else { spdlog::warn("Twitch: unknown raid pool '{}'", list); return std::nullopt; }
			} else part.actions = SplitRaid(list, ',');
		} else {
			const auto bar = token.find('|');
			part.actions = { Trim(token.substr(0, bar)) };
		}
		const auto bar = part.random ? close + 1 : token.find('|');
		const auto suffix = bar == std::string::npos ? std::string{} : Trim(token.substr(bar));
		if (!suffix.empty()) {
			part.counted = true;
			if (suffix[0] != '|') return std::nullopt;
			const auto second = suffix.find('|', 1);
			if (second == std::string::npos || suffix.find('|', second + 1) != std::string::npos ||
				!ParsePositive(Trim(suffix.substr(second + 1)), part.maxCount)) return std::nullopt;
			const auto mid = Trim(suffix.substr(1, second - 1));
			if (mid.starts_with('/')) {
				if (!ParsePositive(mid.substr(1), part.divisor)) return std::nullopt;
			} else if (!ParsePositive(mid, part.minCount) || part.minCount > part.maxCount) return std::nullopt;
		}
		if (part.actions.empty() || std::ranges::any_of(part.actions, [](const auto& a) {
			return a.empty() || a.find_first_of("()+| ") != std::string::npos;
		})) return std::nullopt;
		// ASVS 2.2.1, 1.4.2: validate grammar and bound counts before arithmetic or submission.
		part.maxCount = std::min(part.maxCount, 50);
		part.minCount = std::min(part.minCount, 50);
		return part;
	}

	std::vector<RaidTier> ParseRaidTiers(const TDL_IniData& ini)
	{
		std::vector<RaidTier> tiers;
		std::unordered_map<std::string, std::vector<std::string>> pools;
		if (const auto it = ini.find("raidpools"); it != ini.end())
			for (const auto& [name, value] : it->second) pools[name] = SplitRaid(value, ',');
		if (const auto it = ini.find("raidtiers"); it != ini.end()) for (const auto& [key, value] : it->second) {
			int threshold = 0;
			if (!ParsePositive(key, threshold)) continue;
			RaidTier tier{ threshold, {} };
			for (const auto& group : SplitRaid(value, ',')) {
				std::vector<RaidPart> parts;
				for (const auto& token : SplitRaid(group, '+'))
					if (auto part = ParseRaidPart(token, pools)) parts.push_back(std::move(*part));
				if (!parts.empty()) tier.groups.push_back(std::move(parts));
			}
			if (!tier.groups.empty()) tiers.push_back(std::move(tier));
		}
		return tiers;
	}

	std::vector<RaidTier> RaidTiers()
	{
		std::lock_guard lk(g_cfgMtx);
		return ParseRaidTiers(Ini());
	}

	double RaidMultiplier(const TDL_IniData& ini, int level)
	{
		int best = 0;
		double multiplier = 1.0;
		if (const auto it = ini.find("raidscaling"); it != ini.end())
			for (const auto& [key, value] : it->second) {
				int threshold = 0;
				double factor = 0;
				const auto parsed = std::from_chars(value.data(), value.data() + value.size(), factor);
				if (ParsePositive(key, threshold) && threshold <= level && threshold > best &&
					parsed.ec == std::errc{} && parsed.ptr == value.data() + value.size() &&
					std::isfinite(factor) && factor > 0 && factor <= 10) {
					best = threshold;
					multiplier = factor;
				}
			}
		return multiplier;
	}

	struct RaidScaling { double multiplier = 1.0; int dragonMinLevel = 0; };
	RaidScaling ScalingForLevel(int level)
	{
		RaidScaling scaling;
		if (IniValue("raidscaling", "Enabled") != "1") return scaling;
		scaling.dragonMinLevel = IniInt("raidscaling", "DragonMinLevel", 0);
		std::lock_guard lk(g_cfgMtx);
		scaling.multiplier = RaidMultiplier(Ini(), level);
		return scaling;
	}

	thread_local std::mt19937 g_rng{ std::random_device{}() };
	bool IsBlocked(const std::string& action);
	std::vector<std::string> AllowedRaidActions(const RaidPart& part,
		const std::function<bool(const std::string&)>& blocked)
	{
		std::vector<std::string> allowed;
		for (const auto& action : part.actions) if (!blocked(action)) allowed.push_back(action);
		return allowed;
	}
	RaidActions SelectRaidTier(const std::vector<RaidTier>& tiers, int viewers, bool checkSafety = true,
		double multiplier = 1.0, int playerLevel = 0, int dragonMinLevel = 0)
	{
		if (viewers <= 0) return {};
		const auto effective = [playerLevel, dragonMinLevel](const std::string& action) {
			return action == "SUMMON_DRAGON" && dragonMinLevel > 0 && playerLevel < dragonMinLevel ?
				std::string("SUMMON_STRONG") : action;
		};
		const RaidTier* chosen = nullptr;
		int next = 0;
		for (const auto& tier : tiers)
			if (tier.threshold <= viewers && (!chosen || tier.threshold > chosen->threshold)) chosen = &tier;
		if (!chosen) return {};
		for (const auto& tier : tiers)
			if (tier.threshold > chosen->threshold && (!next || tier.threshold < next)) next = tier.threshold;
		std::vector<size_t> order(chosen->groups.size());
		std::iota(order.begin(), order.end(), 0);
		std::shuffle(order.begin(), order.end(), g_rng);
		for (size_t index : order) {
			RaidActions actions;
			for (const auto& part : chosen->groups[index]) {
				int count = part.minCount;
				if (part.divisor > 0) count = std::max(1, viewers / part.divisor);
				else if (next > chosen->threshold) {
					const auto delta = static_cast<int64_t>(viewers - chosen->threshold) * (part.maxCount - part.minCount);
					count += static_cast<int>((delta + (next - chosen->threshold) / 2) / (next - chosen->threshold));
				}
				count = std::clamp(count, 1, part.maxCount);
				// ASVS 1.4.2, 2.2.1: bound configured scaling before integer conversion and random draws.
				if (part.counted) count = std::clamp(static_cast<int>(std::round(count * multiplier)), 1, 50);
				if (part.random) {
					const auto allowed = AllowedRaidActions(part, [checkSafety, &effective](const std::string& action) {
						return checkSafety && IsBlocked(effective(action));
					});
					if (allowed.empty()) continue;
					// no repeats until the whole list has been used once (then reshuffle)
					auto deck = allowed;
					for (int i = 0; i < count; ++i) {
						if (i % deck.size() == 0) std::shuffle(deck.begin(), deck.end(), g_rng);
						actions.emplace_back(effective(deck[i % deck.size()]), 1);
					}
				} else if (const auto action = effective(part.actions.front()); !checkSafety || !IsBlocked(action)) {
					actions.emplace_back(part.force1 ? "FORCE1|" + action : action, count);
				}
			}
			if (!actions.empty()) return actions;
		}
		return {};
	}

	RaidActions PrepareRaidActions(const RaidActions& selected)
	{
		// ASVS 2.3.2: combine repeated summons before applying the group cap.
		RaidActions merged;
		for (const auto& [action, count] : selected) {
			if (action.starts_with("SUMMON_")) {
				const auto it = std::find_if(merged.begin(), merged.end(), [&](const auto& item) { return item.first == action; });
				if (it != merged.end()) {
					const int kept = std::min(count, 50 - it->second);
					if (kept < count) spdlog::warn("Twitch: raid summon cap trimmed {} from {}", count - kept, action);
					it->second += kept;
					continue;
				}
			}
			merged.emplace_back(action, count);
		}
		RaidActions actions;
		int summoned = 0;
		for (const auto& [action, count] : merged) {
			if (action.starts_with("SUMMON_")) {
				const int kept = std::min(count, 50 - summoned);
				if (kept < count) spdlog::warn("Twitch: raid summon cap trimmed {} from {}", count - kept, action);
				summoned += kept;
				if (!kept) continue;
				actions.emplace_back(action, kept);
			} else for (int i = 0; i < count; ++i) actions.emplace_back(action, 1);
		}
		return actions;
	}

#ifdef _DEBUG
	void CheckRaidTiers()
	{
		assert(ParseTestRaidViewers("0") == 1 && ParseTestRaidViewers("100001") == 100000);
		assert(ParseTestRaidViewers("-5") == 1 && !ParseTestRaidViewers("12x"));
		TDL_IniData ini;
		ini["raidpools"]["chaos"] = "CHAOS_LOW_G, CHAOS_BACKFIRE, GIGANT_BIG, GIGANT_SPEED, WEATHER_STORM, INVENTORY_SCATTER";
		ini["raidpools"]["wrath"] = "WRATH_11, WRATH_12, WRATH_13";
		ini["raidtiers"]["1"] = "FORCE1|SYSTEM_HEALING + SUMMON_SKELETON|1|10 + RANDOM(chaos)|1|1";
		ini["raidtiers"]["11"] = "FORCE1|SYSTEM_HEALING + SUMMON_ANIMAL|3|10 + RANDOM(chaos)|1|2";
		ini["raidtiers"]["31"] = "FORCE1|SYSTEM_HEALING + SUMMON_HUMANOID|3|10 + SUMMON_UNDEAD|1|5 + RANDOM(chaos)|1|2";
		ini["raidtiers"]["71"] = "FORCE1|SYSTEM_HEALING + SUMMON_UNDEAD|5|10 + SUMMON_STRONG|1|5 + RANDOM(chaos)|2|3 + WRATH_11";
		ini["raidtiers"]["121"] = "FORCE1|SYSTEM_HEALING + SUMMON_STRONG|5|10 + RANDOM(chaos)|2|4 + RANDOM(wrath)|1|1";
		ini["raidtiers"]["201"] = "FORCE1|SYSTEM_HEALING + FORCE1|SYSTEM_BLESSING + SUMMON_DRAGON|/30|10 + SUMMON_STRONG|/50|8 + RANDOM(chaos)|2|4 + RANDOM(wrath)|1|2";
		const auto tiers = ParseRaidTiers(ini);
		assert(SelectRaidTier(tiers, 5, false)[1] == std::make_pair(std::string("SUMMON_SKELETON"), 5));
		assert(SelectRaidTier(tiers, 20, false)[1] == std::make_pair(std::string("SUMMON_ANIMAL"), 6));
		assert(SelectRaidTier(tiers, 50, false)[1] == std::make_pair(std::string("SUMMON_HUMANOID"), 6));
		assert(SelectRaidTier(tiers, 100, false)[1] == std::make_pair(std::string("SUMMON_UNDEAD"), 8));
		assert(SelectRaidTier(tiers, 150, false)[1] == std::make_pair(std::string("SUMMON_STRONG"), 7));
		assert(SelectRaidTier(tiers, 300, false)[2] == std::make_pair(std::string("SUMMON_DRAGON"), 10));
		assert(ParseRaidPart("WEATHER_STORM", {}).has_value());
		assert(SplitRaid("WEATHER_RAIN, RANDOM(WEATHER_FOG,WEATHER_SNOW)", ',').size() == 2);
		assert(ParseRaidPart("RANDOM(WEATHER_RAIN,WEATHER_FOG)", {}).has_value());
		TDL_IniData alternatives;
		alternatives["raidtiers"]["1"] = "WEATHER_RAIN, WEATHER_FOG+WEATHER_STORM";
		assert(ParseRaidTiers(alternatives).front().groups.size() == 2);
		assert(!ParseRaidPart("RANDOM(missing)", {}).has_value());
		const auto random = ParseRaidPart("RANDOM(WEATHER_RAIN,VIRUS_WEREWOLF)", {});
		assert(random && AllowedRaidActions(*random, [](const std::string& a) {
			return a == "VIRUS_WEREWOLF";
		}) == std::vector<std::string>{ "WEATHER_RAIN" });
		const auto capped = PrepareRaidActions({ { "SUMMON_UNDEAD", 40 }, { "SUMMON_UNDEAD", 20 },
			{ "SUMMON_DRAGON", 10 }, { "WEATHER_STORM", 1 } });
		assert(capped.size() == 2 && capped[0].second == 50 && capped[1].first == "WEATHER_STORM");
		const auto force = ParseRaidPart("FORCE1|SYSTEM_BLESSING", {});
		assert(force && force->force1 && !force->counted);
		assert(!ParseRaidPart("FORCE1|SYSTEM_BLESSING|2|3", {}).has_value());
		TDL_IniData ordered;
		ordered["raidtiers"]["1"] = "FORCE1|SYSTEM_HEALING + SUMMON_SKELETON|1|10 + FORCE1|SYSTEM_BLESSING";
		const auto picked = PrepareRaidActions(SelectRaidTier(ParseRaidTiers(ordered), 1, false));
		assert(picked.size() == 3 && picked[0].first == "FORCE1|SYSTEM_HEALING" &&
			picked[1].first == "SUMMON_SKELETON" && picked[2].first == "FORCE1|SYSTEM_BLESSING");
		const auto retained = PrepareRaidActions({ { "SUMMON_UNDEAD", 2 }, { "WEATHER_STORM", 1 },
			{ "SUMMON_UNDEAD", 3 } });
		assert(retained.size() == 2 && retained[0].second == 5 && retained[1].first == "WEATHER_STORM");
		const auto repeated = PrepareRaidActions({ { "SUMMON_SKELETON", 30 }, { "SUMMON_SKELETON", 20 } });
		assert(repeated.size() == 1 && repeated[0] == std::make_pair(std::string("SUMMON_SKELETON"), 50));
		const auto dragon = ParseRaidPart("RANDOM(SUMMON_DRAGON)", {});
		assert(dragon && SelectRaidTier({ { 1, { { *dragon } } } }, 1, false, 1.0, 10, 20)[0].first == "SUMMON_STRONG");
		const auto scaled = PrepareRaidActions(SelectRaidTier(ParseRaidTiers(ini), 300, false, 1.5, 10, 20));
		assert(scaled[2].first == "SUMMON_STRONG" && scaled[2].second == 15);
		assert(SelectRaidTier(ParseRaidTiers(ini), 300, false, 1.0, 20, 20)[2].first == "SUMMON_DRAGON");
		TDL_IniData levels;
		levels["raidscaling"]["1"] = "0.5";
		levels["raidscaling"]["11"] = "0.75";
		levels["raidscaling"]["31"] = "1.0";
		levels["raidscaling"]["51"] = "1.25";
		levels["raidscaling"]["76"] = "1.5";
		assert(RaidMultiplier(levels, 1) == 0.5 && RaidMultiplier(levels, 30) == 0.75 &&
			RaidMultiplier(levels, 31) == 1.0 && RaidMultiplier(levels, 51) == 1.25 &&
			RaidMultiplier(levels, 76) == 1.5);
	}
#endif

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

	// Read by the Twitch thread and the outbox thread
	std::mutex g_tokMtx;
	std::string g_access;
	std::string g_userId;

	std::string Token()
	{
		std::lock_guard lk(g_tokMtx);
		return g_access;
	}

	void SetToken(std::string t)
	{
		std::lock_guard lk(g_tokMtx);
		g_access = std::move(t);
	}

	std::string UserId()
	{
		std::lock_guard lk(g_tokMtx);
		return g_userId;
	}

	void SetUserId(std::string id)
	{
		std::lock_guard lk(g_tokMtx);
		g_userId = std::move(id);
	}
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
		SetToken((*j)["access_token"].get<std::string>());
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
		const auto r = Http("GET", "https://id.twitch.tv/oauth2/validate", {}, "Authorization: OAuth " + Token() + "\r\n");
		if (r.status == 0 || r.status >= 500) {
			return Auth::kNetError;
		}
		const auto j = ParseJson(r.body);
		if (r.status != 200 || !j) {
			return Auth::kInvalid;
		}
		// A token from an older plugin version lacks newer scopes: drop it so the user logs in again.
		const auto granted = j->value("scopes", json::array());
		for (std::string_view rest = kScopes; !rest.empty();) {
			const auto sp = rest.find(' ');
			const auto scope = std::string(rest.substr(0, sp));
			rest = sp == std::string_view::npos ? std::string_view{} : rest.substr(sp + 1);
			if (std::find(granted.begin(), granted.end(), scope) == granted.end()) {
				spdlog::warn("Twitch: token lacks scope '{}', login required", scope);
				std::error_code ec;
				std::filesystem::remove(TokenPath(), ec);
				SetToken({});
				return Auth::kInvalid;
			}
		}
		SetUserId(j->value("user_id", ""));
		g_lastValidate = Clock::now();
		spdlog::info("Twitch: logged in as '{}' (id {})", j->value("login", ""), UserId());
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
			SetUserId("12345");
			return Auth::kOk;
		}
		if (!Token().empty()) {
			if (const auto v = Validate(); v != Auth::kInvalid) {
				return v;
			}
		}
		auto a = Refresh();
		if (a == Auth::kOk) {
			a = Validate();  // kInvalid here = refreshed token misses new scopes
		}
		if (a != Auth::kInvalid) {
			return a;
		}
		a = DeviceLogin();
		return a == Auth::kOk ? Validate() : a;
	}

	// ---------------------------------------------------------------- outbox (Helix calls off the event thread)

	struct Job
	{
		std::string method;
		std::string url;
		std::string body;
		std::function<void(bool ok)> done;  // runs on the outbox thread
	};
	std::mutex g_outMtx;
	std::condition_variable g_outCv;
	std::deque<Job> g_out;

	void Post(Job job)
	{
		bool queued = false;
		if (!MockMode()) {  // the Twitch CLI mock server has no Helix chat / channel points endpoints
			std::lock_guard lk(g_outMtx);
			if (g_out.size() <= 100) {  // Twitch unreachable: don't grow without bound
				g_out.push_back(std::move(job));
				queued = true;
			}
		}
		if (queued) {
			g_outCv.notify_one();
		} else if (job.done) {
			job.done(false);
		}
	}

	// Chat replies, redemption updates and reward creation run here, so a slow Helix call never delays EventSub.
	void OutboxThread()
	{
		for (;;) {
			Job job;
			{
				std::unique_lock lk(g_outMtx);
				g_outCv.wait(lk, [] { return !g_out.empty(); });
				job = std::move(g_out.front());
				g_out.pop_front();
			}
			const auto r = Http(job.method.c_str(), job.url, job.body,
				"Authorization: Bearer " + Token() + "\r\nClient-Id: " + kClientId + "\r\nContent-Type: application/json\r\n");
			const bool ok = r.status >= 200 && r.status < 300;
			if (!ok) {
				spdlog::warn("Twitch: {} {} -> {} {}", job.method, job.url, r.status, r.body);
			}
			if (job.done) {
				job.done(ok);
			}
			std::this_thread::sleep_for(std::chrono::milliseconds(250));  // stay far below Helix / chat rate limits
		}
	}

	void ChatSay(const std::string& text)
	{
		if (text.empty() || IniValue("chatreplies", "Enabled") == "0") {
			return;
		}
		// Chat allows 500 characters; cut on a UTF-8 boundary (a split character would make json::dump throw)
		size_t cut = std::min<size_t>(text.size(), 480);
		while (cut > 0 && cut < text.size() && (static_cast<unsigned char>(text[cut]) & 0xC0) == 0x80) {
			--cut;
		}
		const auto uid = UserId();
		Post({ "POST", "https://api.twitch.tv/helix/chat/messages",
			json{ { "broadcaster_id", uid }, { "sender_id", uid }, { "message", text.substr(0, cut) } }.dump(-1, ' ', false,
				json::error_handler_t::replace) });
	}

	struct ViewerStats
	{
		std::string name;
		uint64_t actions = 0;
		uint64_t bits = 0;
		uint64_t redemptions = 0;
		std::time_t lastSeen = 0;
	};
	// ASVS 15.4.1: EventSub, scheduler, overlay and timer share this state under one mutex.
	std::mutex g_statsMtx;
	std::unordered_map<std::string, ViewerStats> g_stats;
	uint64_t g_statsVersion = 0;
	uint64_t g_savedVersion = 0;
	Clock::time_point g_lastStatsSave{};
	bool g_statsBackupFailed = false;
	bool g_stopping = false;

	std::filesystem::path StatsPath()
	{
#ifndef TDL_TWITCH_HARNESS
		auto dir = SKSE::log::log_directory();
		return dir ? *dir / "TDL_Stats.json" : std::filesystem::path{};
#else
		return std::filesystem::temp_directory_path() / "TDL_Stats.json";
#endif
	}

	json StatsJson(const std::unordered_map<std::string, ViewerStats>& stats)
	{
		json users = json::object();
		for (const auto& [id, s] : stats)
			users[id] = { { "name", s.name }, { "actions", s.actions }, { "bits", s.bits },
				{ "redemptions", s.redemptions }, { "lastSeen", s.lastSeen } };
		return { { "users", std::move(users) } };
	}

	std::unordered_map<std::string, ViewerStats> ParseStats(const json& data)
	{
		std::unordered_map<std::string, ViewerStats> result;
		const auto& users = data.at("users");
		if (!users.is_object() || users.size() > 100000) throw std::runtime_error("invalid users");
		for (auto it = users.begin(); it != users.end(); ++it) {
			if (it.key().empty() || it.key().size() > 64 || !it.value().is_object()) throw std::runtime_error("invalid viewer");
			const auto& v = it.value();
			if (!v.at("name").is_string() || v.at("name").get_ref<const std::string&>().size() > 128)
				throw std::runtime_error("invalid viewer name");
			result.emplace(it.key(), ViewerStats{ v.at("name").get<std::string>(),
				v.at("actions").get<uint64_t>(), v.at("bits").get<uint64_t>(),
				v.at("redemptions").get<uint64_t>(), v.at("lastSeen").get<std::time_t>() });
		}
		return result;
	}

	void LoadStats()
	{
		const auto path = StatsPath();
		if (path.empty() || IniValue("stats", "Enabled", "1") == "0") return;
		if (IniValue("stats", "ResetOnStart") == "1") {
			std::lock_guard lk(g_statsMtx);
			++g_statsVersion;
			return;
		}
		std::error_code ec;
		if (!std::filesystem::exists(path, ec)) return;
		try {
			if (std::filesystem::file_size(path) > 4 * 1024 * 1024) throw std::runtime_error("file too large");
			std::ifstream f(path, std::ios::binary);
			if (!f) throw std::runtime_error("open failed");
			json data = json::parse(f);
			auto loaded = ParseStats(data);  // ASVS 1.5.1, 2.2.1: validate persisted JSON before use.
			std::lock_guard lk(g_statsMtx);
			g_stats = std::move(loaded);
		} catch (const std::exception& e) {
			spdlog::warn("Twitch: bad stats file: {}", e.what());
			std::filesystem::copy_file(path, path.string() + ".bad", std::filesystem::copy_options::overwrite_existing, ec);
			if (ec) {
				spdlog::warn("Twitch: stats backup failed: {}", ec.message());
				std::lock_guard lk(g_statsMtx);
				g_statsBackupFailed = true;
			}
		}
	}

	void SaveStats(bool force = false)
	{
		if (IniValue("stats", "Enabled", "1") == "0") return;
		const auto path = StatsPath();
		if (path.empty()) return;
		json data;
		uint64_t version;
		{
			std::lock_guard lk(g_statsMtx);
			if (g_statsBackupFailed || g_statsVersion == g_savedVersion || (!force && Clock::now() - g_lastStatsSave < 30s)) return;
			data = StatsJson(g_stats);
			version = g_statsVersion;
			g_lastStatsSave = Clock::now();
		}
		const auto tmp = std::filesystem::path(path.string() + ".tmp");
		{
			std::ofstream f(tmp, std::ios::binary | std::ios::trunc);
			if (!f || !(f << data.dump(-1, ' ', false, json::error_handler_t::replace)) || !f.flush()) {
				spdlog::warn("Twitch: stats temp write failed");
				return;
			}
		}
		// ASVS 15.4.1: replace only after a complete write; old data survives write failure.
		if (!MoveFileExW(tmp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
			spdlog::warn("Twitch: stats replace failed: {}", GetLastError());
			return;
		}
		std::lock_guard lk(g_statsMtx);
		g_savedVersion = version;
	}

	void SeeViewer(const std::string& id, const std::string& name, int bits = 0, bool redemption = false)
	{
		if (id.empty() || id.size() > 64 || IniValue("stats", "Enabled", "1") == "0") return;
		std::lock_guard lk(g_statsMtx);
		if (g_stopping) return;
		auto& s = g_stats[id];
		if (!name.empty() && name.size() <= 128) s.name = name;
		s.lastSeen = std::time(nullptr);
		if (bits > 0) s.bits += static_cast<uint64_t>(bits);
		if (redemption) ++s.redemptions;
		++g_statsVersion;
	}

	json TopViewers()
	{
		if (IniValue("stats", "Enabled", "1") == "0") return json::array();
		std::vector<ViewerStats> rows;
		{
			std::lock_guard lk(g_statsMtx);
			for (const auto& [id, s] : g_stats) if (s.actions) rows.push_back(s);
		}
		std::sort(rows.begin(), rows.end(), [](const auto& a, const auto& b) {
			return a.actions != b.actions ? a.actions > b.actions : a.name < b.name;
		});
		json top = json::array();
		for (size_t i = 0; i < std::min<size_t>(5, rows.size()); ++i)
			top.push_back({ { "name", rows[i].name }, { "actions", rows[i].actions } });
		return top;
	}

	std::string Expand(const std::string&, const std::vector<std::pair<std::string, std::string>>&);
	void SayStats(const std::string& id, const std::string& name, bool top)
	{
		if (IniValue("stats", "Enabled", "1") == "0") return;
		if (top) {
			const auto rows = TopViewers();
			std::string reply;
			for (size_t i = 0; i < rows.size(); ++i)
				reply += (i ? ", " : "") + std::to_string(i + 1) + ") " + rows[i]["name"].get<std::string>() +
					" " + std::to_string(rows[i]["actions"].get<uint64_t>());
			ChatSay(rows.empty() ? "TDL top: no actions yet" :
				Expand(IniValue("chatreplies", "Top", "TDL top: {top}"), { { "{top}", reply } }));
		} else {
			ViewerStats s;
			{ std::lock_guard lk(g_statsMtx); if (auto it = g_stats.find(id); it != g_stats.end()) s = it->second; }
			ChatSay(Expand(IniValue("chatreplies", "Me", "@{user} TDL: {actions} actions, {bits} bits, {redemptions} redemptions"),
				{ { "{user}", name }, { "{actions}", std::to_string(s.actions) }, { "{bits}", std::to_string(s.bits) },
					{ "{redemptions}", std::to_string(s.redemptions) } }));
		}
	}

	bool Submit(const std::string&, int, const std::string&, const std::string&, const std::string& = {},
		const std::string& = {}, const std::string& = {}, bool = false, bool = false, const std::string& = {});
	struct VoteOption { std::string action, label; int votes = 0; };
	struct VoteState
	{
		std::vector<VoteOption> options;
		std::unordered_map<std::string, size_t> byUser;
		Clock::time_point ends{};
	};
	std::mutex g_voteMtx;
	std::condition_variable g_voteCv;
	std::optional<VoteState> g_vote;
	uint64_t g_voteCancelGeneration = 0;
	std::atomic_bool g_voteStop{ false };
	std::thread g_voteThread;
	Clock::time_point g_nextVote{};
	std::unordered_map<std::string, int> g_hypeLevels;

	bool IsBlocked(const std::string& action)
	{
		const auto blocked = LowerAscii(IniValue("safety", "Blocked", "VIRUS_WEREWOLF, VIRUS_VAMPIRE, INVENTORY_DROP_ALL"));
		for (size_t p = 0; p < blocked.size();) {
			const auto comma = std::min(blocked.find(',', p), blocked.size());
			if (Trim(blocked.substr(p, comma - p)) == LowerAscii(action)) return true;
			p = comma + 1;
		}
		return false;
	}

	bool ApplyVote(VoteState& vote, const std::string& id, size_t choice)
	{
		if (id.empty() || choice >= vote.options.size()) return false;
		if (auto old = vote.byUser.find(id); old != vote.byUser.end()) --vote.options[old->second].votes;
		vote.byUser[id] = choice;
		++vote.options[choice].votes;
		return true;
	}

	std::optional<size_t> VoteWinner(const VoteState& vote, int minVotes)
	{
		if (vote.byUser.size() < static_cast<size_t>(minVotes) || vote.options.empty()) return std::nullopt;
		int best = -1;
		std::vector<size_t> tied;
		for (size_t i = 0; i < vote.options.size(); ++i) {
			if (vote.options[i].votes > best) { best = vote.options[i].votes; tied.clear(); }
			if (vote.options[i].votes == best) tied.push_back(i);
		}
		return tied[std::uniform_int_distribution<size_t>(0, tied.size() - 1)(g_rng)];
	}

	void CancelVote()
	{
		std::lock_guard lk(g_voteMtx);
		++g_voteCancelGeneration;
		g_vote.reset();
		g_voteCv.notify_all();
	}

	std::vector<std::string> SplitList(const std::string& text)
	{
		std::vector<std::string> values;
		for (size_t p = 0; p < text.size();) {
			const auto comma = std::min(text.find(',', p), text.size());
			if (auto item = Trim(text.substr(p, comma - p)); !item.empty()) values.push_back(std::move(item));
			p = comma + 1;
		}
		return values;
	}

	void StartVote()
	{
		if (!g_connected.load() || TDL_IsTwitchPaused()) return;
		auto pool = SplitList(IniValue("autopoll", "Pool", "WEATHER_STORM, SUMMON_ANIMAL, GIGANT_SMALL, SYSTEM_HEALING, SUMMON_SKELETON, WEATHER_RAIN"));
		pool.erase(std::remove_if(pool.begin(), pool.end(), [](const auto& a) { return IsBlocked(a) || a.find('|') != std::string::npos; }), pool.end());
		std::sort(pool.begin(), pool.end());
		pool.erase(std::unique(pool.begin(), pool.end()), pool.end());
		const size_t choices = std::clamp(IniInt("autopoll", "Choices", 3), 2, 9);
		if (pool.size() < choices) { spdlog::warn("Twitch: AutoPoll pool has too few safe actions"); return; }
		std::shuffle(pool.begin(), pool.end(), g_rng);
		const int duration = std::clamp(IniInt("autopoll", "DurationSec", 60), 10, 600);
		VoteState vote;
		vote.ends = Clock::now() + std::chrono::seconds(duration);
		std::string labels;
		for (size_t i = 0; i < choices; ++i) {
			auto label = IniValue("messages", pool[i]);
			if (label.empty()) label = pool[i];
			else label = Trim(Expand(label, { { "{user}", "" }, { "{trigger}", "" } }));
			vote.options.push_back({ pool[i], label, 0 });
			labels += std::to_string(i + 1) + ") " + label + " ";
		}
		const auto announce = Expand(IniValue("chatreplies", "AutoPollStart", "Vote: {options} - type !1..!{choices} ({seconds}s)"),
			{ { "{options}", labels }, { "{choices}", std::to_string(choices) }, { "{seconds}", std::to_string(duration) } });
		{
			std::lock_guard lk(g_voteMtx);
			if (g_vote || !g_connected.load() || g_paused.load()) return;
			g_vote = std::move(vote);
		}
		ChatSay(announce);
		g_voteCv.notify_all();
	}

	void FinishVote(VoteState vote, uint64_t generation)
	{
		const auto canceled = [&] { std::lock_guard lk(g_voteMtx); return generation != g_voteCancelGeneration; };
		if (canceled()) return;
		if (TDL_IsTwitchPaused()) return;
		const auto winner = VoteWinner(vote, std::max(1, IniInt("autopoll", "MinVotes", 1)));
		if (!winner) { if (!canceled()) ChatSay(IniValue("chatreplies", "AutoPollNoVotes", "TDL: no votes")); return; }
		std::string counts;
		for (size_t i = 0; i < vote.options.size(); ++i)
			counts += (i ? ", " : "") + std::to_string(i + 1) + ":" + std::to_string(vote.options[i].votes);
		if (canceled()) return;
		ChatSay(Expand(IniValue("chatreplies", "AutoPollWin", "TDL: {winner} won ({counts})"),
			{ { "{winner}", vote.options[*winner].label }, { "{counts}", counts } }));
		if (canceled()) return;
		Submit(vote.options[*winner].action, kSourceVote, "", "AutoPoll: " + vote.options[*winner].label,
			{}, {}, {}, false, false);
	}

	void VoteThread()
	{
		const auto interval = [] { return std::chrono::minutes(std::clamp(IniInt("autopoll", "IntervalMin", 10), 1, 1440)); };
		std::unique_lock lk(g_voteMtx);
		lk.unlock(); auto initial = interval(); lk.lock();
		g_nextVote = Clock::now() + initial;
		while (!g_voteStop.load()) {
			const auto deadline = std::min(g_vote ? g_vote->ends : g_nextVote, Clock::now() + 30s);
			g_voteCv.wait_until(lk, deadline);
			if (g_voteStop.load()) break;
			if (g_vote && Clock::now() >= g_vote->ends) {
				auto done = std::move(*g_vote);
				const auto generation = g_voteCancelGeneration;
				g_vote.reset();
				lk.unlock(); FinishVote(std::move(done), generation); lk.lock();
			} else if (!g_vote && Clock::now() >= g_nextVote) {
				lk.unlock();
				const auto next = Clock::now() + interval();
				if (IniValue("autopoll", "Enabled") == "1") StartVote();
				lk.lock();
				g_nextVote = next;
			}
			lk.unlock(); SaveStats(); lk.lock();
		}
	}

#ifdef _DEBUG
	void CheckBatch3Logic()
	{
		VoteState v;
		v.options = { { "A", "A" }, { "B", "B" } };
		assert(ApplyVote(v, "u", 0) && ApplyVote(v, "v", 1));
		assert(!VoteWinner(v, 3));
		assert(ApplyVote(v, "u", 1) && v.options[0].votes == 0 && v.options[1].votes == 2);
		assert(VoteWinner(v, 1) == 1);
		assert(ApplyVote(v, "u", 0) && v.options[0].votes == v.options[1].votes);
		assert(VoteWinner(v, 1).value() < 2);
		std::unordered_map<std::string, ViewerStats> original{ { "42", { "Alice", 3, 100, 1, 1234 } } };
		const auto roundTrip = ParseStats(json::parse(StatsJson(original).dump())).at("42");
		assert(roundTrip.name == "Alice" && roundTrip.actions == 3 && roundTrip.bits == 100 &&
			roundTrip.redemptions == 1 && roundTrip.lastSeen == 1234);
	}
#endif

	// Only works for rewards created by this app (CreateRewards=1); Twitch answers 403 for rewards made in the dashboard.
	void SetRedemptionStatus(const std::string& rewardId, const std::string& redemptionId, const char* status,
		std::function<void(bool)> done = {})
	{
		if (rewardId.empty() || redemptionId.empty()) {
			if (done) {
				done(false);
			}
			return;
		}
		Post({ "PATCH",
			"https://api.twitch.tv/helix/channel_points/custom_rewards/redemptions?broadcaster_id=" + UserId() +
				"&reward_id=" + UrlEncode(rewardId) + "&id=" + UrlEncode(redemptionId),
			json{ { "status", status } }.dump(), std::move(done) });
	}

	// ---------------------------------------------------------------- event -> action

	struct UserState
	{
		int queued = 0;
		Clock::time_point lastAccepted{};
		Clock::time_point lastWarn{};
		std::unordered_map<std::string, Clock::time_point> seenCommands;
	};
	// ASVS 15.4.1, 2.3.4: reserve queue slots under one lock; outcome callbacks release them.
	std::mutex g_userMtx;
	std::unordered_map<std::string, UserState> g_users;

	enum class ChatDecision { kAllow, kDuplicate, kCooldown };
	ChatDecision CheckChat(const UserState& state, const std::string& command, Clock::time_point now,
		int duplicateSec, int cooldownSec, bool privileged)
	{
		if (const auto it = state.seenCommands.find(command);
			it != state.seenCommands.end() && now - it->second < std::chrono::seconds(duplicateSec)) {
			return ChatDecision::kDuplicate;
		}
		if (!privileged && state.lastAccepted.time_since_epoch().count() != 0 &&
			now - state.lastAccepted < std::chrono::seconds(cooldownSec)) {
			return ChatDecision::kCooldown;
		}
		return ChatDecision::kAllow;
	}

#ifdef _DEBUG
	void CheckAntiSpamLogic()
	{
		const auto now = Clock::now();
		UserState state{ 0, now - 2s, {}, { { "!tdl_heal", now - 2s } } };
		assert(CheckChat(state, "!tdl_heal", now, 5, 20, false) == ChatDecision::kDuplicate);
		assert(CheckChat(state, "!tdl_ping", now, 5, 20, false) == ChatDecision::kCooldown);
		assert(CheckChat(state, "!tdl_ping", now, 5, 20, true) == ChatDecision::kAllow);
	}
#endif

	// Single pass over the template, so a viewer named "{trigger}" is not expanded again.
	std::string Expand(const std::string& tmpl, const std::vector<std::pair<std::string, std::string>>& vars)
	{
		std::string out;
		for (size_t i = 0; i < tmpl.size();) {
			bool replaced = false;
			for (const auto& [key, value] : vars) {
				if (tmpl.compare(i, key.size(), key) == 0) {
					out += value;
					i += key.size();
					replaced = true;
					break;
				}
			}
			if (!replaced) {
				out += tmpl[i++];
			}
		}
		return out;
	}

	// Cancel the redemption (refunds the points), then answer in chat; "{refund}" is filled in only
	// when Twitch confirmed the cancel (it refuses for rewards not created by this app).
	void RefundAndSay(const char* replyKey, std::vector<std::pair<std::string, std::string>> vars, const std::string& rewardId,
		const std::string& redemptionId)
	{
		SetRedemptionStatus(rewardId, redemptionId, "CANCELED", [replyKey, vars = std::move(vars)](bool refunded) mutable {
			vars.push_back({ "{refund}", refunded ? IniValue("chatreplies", "Refunded") : std::string{} });
			ChatSay(Expand(IniValue("chatreplies", replyKey), vars));
		});
	}

	// [Messages] ACTION={user} ... describes what happened; falls back to "viewer: trigger". UTF-8.
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
		return !tmpl.empty() ? Expand(tmpl, { { "{user}", name }, { "{trigger}", trigger } }) :
		       name.empty()  ? trigger :
		                       name + ": " + trigger;
	}

	// Value is "ACTION", "A,B,C" (random pick, used for difficulty tiers) or a raw pipe line ("FORCE|ACTION|5").
	// who: viewer name (empty for polls); trigger: what they used, in the streamer's own words (reward title, "500 bits", "!cmd").
	// rewardId/redemptionId: an unfulfilled channel points redemption to fulfil or refund.
	bool Submit(const std::string& value, int source, const std::string& who, const std::string& trigger,
		const std::string& rewardId, const std::string& redemptionId, const std::string& userId,
		bool chat, bool privileged, const std::string& notice)
	{
		const auto reject = [&](const char* key) {
			if (!redemptionId.empty()) {
				RefundAndSay(key, { { "{user}", who }, { "{trigger}", trigger } }, rewardId, redemptionId);
			} else if (who.empty()) {
				ChatSay(std::string("TDL: ") + (std::string_view(key) == "Paused" ? "paused" : "action rejected"));
			} else if (!chat || userId.empty()) {
				ChatSay(Expand(IniValue("chatreplies", key), { { "{user}", who }, { "{trigger}", trigger } }));
			} else {
				const auto now = Clock::now();
				const int window = IniInt("antispam", "UserCooldownSec", 20);
				bool say = false;
				{
					std::lock_guard lk(g_userMtx);
					auto& state = g_users[userId];
					if (state.lastWarn.time_since_epoch().count() == 0 || now - state.lastWarn >= std::chrono::seconds(window)) {
						state.lastWarn = now;
						say = true;
					}
				}
				if (say) ChatSay(Expand(IniValue("chatreplies", key), { { "{user}", who }, { "{trigger}", trigger } }));
			}
		};
		(void)IniValue("twitch", "Paused");  // reload changed INI before reading the state
		const bool held = g_paused.load() && g_pauseHold.load();
		if (g_paused.load() && !held) {
			reject("Paused");
			return false;
		}
		if (value.empty()) {
			if (!redemptionId.empty()) reject("Blocked");
			return false;
		}
		std::vector<std::string> options;
		for (size_t pos = 0; pos <= value.size();) {
			const auto comma = std::min(value.find(',', pos), value.size());
			if (auto opt = Trim(value.substr(pos, comma - pos)); !opt.empty()) {
				const auto bar = opt.find('|');
				const bool force = opt.rfind("FORCE|", 0) == 0 || opt.rfind("FORCE1|", 0) == 0;
				const auto action = force ? opt.substr(bar + 1, opt.find('|', bar + 1) - bar - 1) : opt.substr(0, bar);
				const auto blocked = "," + LowerAscii(IniValue("safety", "Blocked",
					"VIRUS_WEREWOLF, VIRUS_VAMPIRE, INVENTORY_DROP_ALL")) + ",";
				bool forbidden = false;
				for (size_t p = 0; p < blocked.size();) {
					const auto next = blocked.find(',', p);
					if (next == std::string::npos) break;
					if (Trim(blocked.substr(p, next - p)) == LowerAscii(action)) forbidden = true;
					p = next + 1;
				}
				if (!forbidden && (!force || privileged || IniValue("safety", "AllowForceFromViewers") == "1"))
					options.push_back(std::move(opt));
			}
			pos = comma + 1;
		}
		if (options.empty()) {
			spdlog::info("Twitch: {} by {} -> no mapping", trigger, who);
			reject("Blocked");
			return false;
		}
		const bool counted = !userId.empty() && (source != kSourceBits || IniValue("antispam", "ExemptBits") == "0");
		if (counted) {
			const int maxQueued = IniInt("antispam", "MaxQueuedPerUser", 2);
			bool full = false;
			{
				std::lock_guard lk(g_userMtx);
				auto& state = g_users[userId];
				full = state.queued >= maxQueued;
				if (!full) ++state.queued;
			}
			if (full) {
				reject("TooMany");
				return false;
			}
		}
		const auto& action = options[std::uniform_int_distribution<size_t>(0, options.size() - 1)(g_rng)];
		const auto line = action.find('|') == std::string::npos ? action + "|" + std::to_string(source) : action;
		spdlog::info("Twitch: {} by {} -> {}", trigger, who, line);

		const TDL_Origin origin{ notice == "\x01" ? std::string{} : notice.empty() ? BuildNotice(line, who, trigger) :
			(IniValue("twitch", "Notify", "1") == "0" ? std::string{} : notice), who, trigger, rewardId, redemptionId,
			counted ? userId : std::string{}, true, userId };
		const auto info = TDL_SubmitLine(line, origin);
		const std::vector<std::pair<std::string, std::string>> vars = { { "{user}", who }, { "{trigger}", trigger },
			{ "{pos}", std::to_string(info.position) }, { "{eta}", std::to_string(info.etaSec) } };
		if (!info.accepted) {
			if (counted) { std::lock_guard lk(g_userMtx); --g_users[userId].queued; }
			reject("Dropped");
		} else if (held) {
			ChatSay(Expand(IniValue("chatreplies", "PausedHeld", "@{user}, TDL на паузе, команда в очереди"), vars));
		} else if (who.empty() || !notice.empty()) {
			return true;
		} else if (info.etaSec >= 5) {
			ChatSay(Expand(IniValue("chatreplies", "Queued"), vars));
		} else {
			ChatSay(Expand(IniValue("chatreplies", "Now"), vars));
		}
		return info.accepted;
	}

	// Scheduler thread: an action fired, or a higher-priority one pushed it out of a full queue.
	void OnOutcome(const TDL_Origin& o, bool fired)
	{
		if (!o.queueUser.empty()) {
			std::lock_guard lk(g_userMtx);
			--g_users[o.queueUser].queued;
		}
		if (fired) {
				if (!o.userId.empty() && IniValue("stats", "Enabled", "1") != "0") {
				std::lock_guard lk(g_statsMtx);
					if (!g_stopping) {
						auto& s = g_stats[o.userId];
						if (s.name.empty()) s.name = o.who;
						++s.actions;
						s.lastSeen = std::time(nullptr);
						++g_statsVersion;
					}
			}
			SetRedemptionStatus(o.rewardId, o.redemptionId, "FULFILLED");
		} else if (o.who.empty()) {
			if (g_paused.load() && o.twitch) ChatSay("TDL paused");
			SetRedemptionStatus(o.rewardId, o.redemptionId, "CANCELED");
		} else {
			RefundAndSay(g_paused.load() ? "Paused" : "Evicted",
				{ { "{user}", o.who }, { "{trigger}", o.trigger } }, o.rewardId, o.redemptionId);
		}
	}

	std::string BitsMapping(int bits)
	{
		// Largest threshold not above the cheered amount wins.
		std::lock_guard lk(g_cfgMtx);
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

	// [section] keys with their original case (the shared INI loader lowercases them)
	std::vector<std::string> RawSectionKeys(const char* section)
	{
		std::vector<std::string> keys;
		std::ifstream f(IniPath());
		std::string line;
		bool in = false;
		while (std::getline(f, line)) {
			line = Trim(line);
			if (line.empty() || line[0] == ';' || line[0] == '#') {
				continue;
			}
			if (line.front() == '[' && line.back() == ']') {
				in = LowerAscii(Trim(line.substr(1, line.size() - 2))) == section;
			} else if (in) {
				if (const auto eq = line.find('='); eq != std::string::npos && eq > 0) {
					keys.push_back(Trim(line.substr(0, eq)));
				}
			}
		}
		return keys;
	}

	// "!tdl": what viewers can use. Rate-limited so it cannot be used to spam the chat.
	void SayHelp()
	{
		static Clock::time_point last{};
		if (Clock::now() - last < std::chrono::seconds(30)) {
			return;
		}
		last = Clock::now();

		auto join = [](const std::vector<std::string>& v, const char* sep) {
			std::string s;
			for (const auto& x : v) {
				s += (s.empty() ? "" : sep) + x;
			}
			return s;
		};
		std::vector<std::string> bits;
		for (const auto& k : RawSectionKeys("bits")) {
			bits.push_back(k + "+");
		}
		const auto vars = std::vector<std::pair<std::string, std::string>>{ { "{rewards}", join(RawSectionKeys("rewards"), " | ") },
			{ "{bits}", join(bits, ", ") }, { "{commands}", join(RawSectionKeys("chat"), " ") +
				" !tdl raid <viewers> [name] / !tdl_raid (broadcaster/mods) / !tdl settings (broadcaster)" } };
		auto help = Expand(IniValue("chatreplies", "Help"), vars);
		if (help.find("!tdl settings") == std::string::npos) help += " | !tdl settings (broadcaster)";
		ChatSay(help);
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

	void HandleRaidOnGameThread(int viewers, const std::string& who, const std::string& id)
	{
		(void)IniValue("twitch", "Paused");
		if (g_paused.load() && !g_pauseHold.load()) return;
		const auto trigger = "Raid (" + std::to_string(viewers) + ")";
		const auto tiers = RaidTiers();
		if (tiers.empty()) {
			Submit(IniValue("events", "Raid", "SUMMON_ANY"), kSourceBits, who, trigger, {}, {}, id);
			return;
		}
#ifndef TDL_TWITCH_HARNESS
		const auto* player = RE::PlayerCharacter::GetSingleton();
		const int level = player ? player->GetLevel() : 0;
#else
		const int level = 1;
#endif
		const auto scaling = ScalingForLevel(level);
		const auto actions = PrepareRaidActions(SelectRaidTier(tiers, viewers, true,
			scaling.multiplier, level, scaling.dragonMinLevel));
		if (actions.empty()) return;
		std::string list;
		for (const auto& [action, count] : actions)
			list += (list.empty() ? "" : ", ") + (count > 1 ? std::to_string(count) + "x " : "") + action;
		spdlog::info("Raid: viewers={} level={} x{:.2f} -> {}", viewers, level, scaling.multiplier, list);
		const auto vars = std::vector<std::pair<std::string, std::string>>{
			{ "{user}", who }, { "{viewers}", std::to_string(viewers) }, { "{list}", list },
			{ "{count}", std::to_string(actions.front().second) }, { "{action}", actions.front().first } };
		int threshold = 0;
		for (const auto& tier : tiers)
			if (tier.threshold <= viewers) threshold = std::max(threshold, tier.threshold);
		const auto special = IniValue("raidnotices", std::to_string(threshold));
		const auto message = Expand(special.empty() ? IniValue("messages", "RAID",
			"{user} raids with {viewers} viewers: {list}") : special, vars);
		if (!special.empty() && IniValue("twitch", "Notify", "1") != "0") TDL_Notify(message);
		const bool heldRaid = TDL_IsTwitchPaused() && TDL_IsTwitchPauseHold();
		if (heldRaid && special.empty() && IniValue("twitch", "Notify", "1") != "0") TDL_Notify(message);
		bool accepted = false;
		for (const auto& [action, count] : actions) {
			const auto value = action.starts_with("SUMMON_") ?
				"FORCE|" + action + "|" + std::to_string(count) : action;
			if (Submit(value, kSourceBits, who, trigger, {}, {}, id, false, true,
				special.empty() && !accepted && !heldRaid ? message : "\x01")) accepted = true;
		}
		if (accepted) ChatSay(message);
	}

	void HandleRaid(int viewers, const std::string& who, const std::string& id)
	{
		SeeViewer(id, who);
		if (viewers <= 0 || viewers < IniInt("events", "RaidMinViewers", 1)) return;
		// ASVS 15.4.1: resolve player state and counts together on the game thread.
#ifndef TDL_TWITCH_HARNESS
		if (auto* tasks = SKSE::GetTaskInterface(); tasks)
			tasks->AddTask([viewers, who, id] { HandleRaidOnGameThread(viewers, who, id); });
#else
		HandleRaidOnGameThread(viewers, who, id);
#endif
	}

	void HandleEvent(const std::string& type, const json& ev)
	{
		if (type == "channel.channel_points_custom_reward_redemption.add") {
			const auto& reward = ev.at("reward");
			const auto title = reward.value("title", "");
			SeeViewer(Str(ev, "user_id", ""), Str(ev, "user_name", "?"), 0, true);
			// Rewards that skip the request queue arrive already "fulfilled": nothing to fulfil or refund then.
			const bool pending = ev.value("status", "") == "unfulfilled";
			Submit(IniValue("rewards", title), kSourcePoints, Str(ev, "user_name", "?"), title,
				pending ? reward.value("id", "") : std::string{}, pending ? ev.value("id", "") : std::string{}, Str(ev, "user_id", ""));
		} else if (type == "channel.cheer") {
			const int bits = std::max(0, ev.value("bits", 0));
			SeeViewer(Str(ev, "user_id", ""), Str(ev, "user_name", "Anonymous"), bits);
			Submit(BitsMapping(bits), kSourceBits, Str(ev, "user_name", "Anonymous"), std::to_string(bits) + " bits",
				{}, {}, Str(ev, "user_id", ""));
		} else if (type == "channel.chat.message") {
			const auto text = Trim(ev.at("message").value("text", ""));
			const auto chatterId = Str(ev, "chatter_user_id", "");
			const auto chatterName = Str(ev, "chatter_user_name", "?");
			SeeViewer(chatterId, chatterName);
			if (text.empty() || text[0] != '!') {
				return;
			}
			const auto cmd = LowerAscii(text.substr(0, text.find(' ')));
			const auto privileged = IsPrivileged(ev);
			if (LowerAscii(text) == "!tdl settings") {
				bool broadcaster = false;
				for (const auto& badge : ev.value("badges", json::array()))
					if (badge.is_object() && badge.value("set_id", "") == "broadcaster") broadcaster = true;
				if (broadcaster) {
					if (TDL_OpenSettings()) ChatSay("Settings opened on the streamer PC");
				}
				return;
			}
			if (text.size() == 2 && text[1] >= '1' && text[1] <= '9') {
				std::lock_guard lk(g_voteMtx);
				if (g_vote && Clock::now() < g_vote->ends) ApplyVote(*g_vote, chatterId, text[1] - '1');
				return;
			}
			if (cmd == "!tdl" && (text == "!tdl top" || text == "!tdl me")) {
				if (!chatterId.empty()) {
					std::lock_guard lk(g_userMtx);
					auto& user = g_users[chatterId];
					const auto now = Clock::now();
					if (CheckChat(user, text, now, IniInt("antispam", "IgnoreDuplicateSec", 5),
						IniInt("antispam", "UserCooldownSec", 20), privileged) != ChatDecision::kAllow) return;
					user.seenCommands[text] = now;
					user.lastAccepted = now;
				}
				SayStats(chatterId, chatterName, text == "!tdl top");
				return;
			}
			if (cmd == "!tdl" && (text == "!tdl poll" || text == "!tdl poll stop")) {
				if (!privileged) return;
				if (text == "!tdl poll stop") { CancelVote(); ChatSay(IniValue("chatreplies", "AutoPollCanceled", "TDL: vote canceled")); }
				else StartVote();
				return;
			}
			const auto raidArgs = Trim(text.substr(cmd.size()));
			const auto raidWordEnd = raidArgs.find_first_of(" \t");
			if (cmd == "!tdl_raid" || (cmd == "!tdl" && LowerAscii(raidArgs.substr(0, raidWordEnd)) == "raid")) {
				if (!privileged) return;  // ASVS 8.2.1: test raids require a broadcaster/mod badge.
				const auto args = cmd == "!tdl" ? Trim(raidArgs.substr(raidWordEnd == std::string::npos ? raidArgs.size() : raidWordEnd)) : raidArgs;
				const auto numberEnd = args.find_first_of(" \t");
				const auto viewers = ParseTestRaidViewers(std::string_view(args).substr(0, numberEnd));
				if (!viewers) return;
				const auto name = numberEnd == std::string::npos ? std::string{} : Trim(args.substr(numberEnd));
				spdlog::info("Twitch: test raid viewers={} from '{}'", *viewers, name.empty() ? chatterName : name);
				ChatSay("Test raid: " + std::to_string(*viewers));
				HandleRaid(*viewers, name.empty() ? chatterName : name, chatterId);
				return;
			}
			if (cmd == "!tdl_pause" || cmd == "!tdl_resume" ||
				(cmd == "!tdl" && (LowerAscii(Trim(text.substr(cmd.size()))) == "pause" ||
					LowerAscii(Trim(text.substr(cmd.size()))) == "resume"))) {
				if (!privileged) return;  // ASVS 8.2.1: pause controls require a broadcaster/mod badge.
				const bool pause = cmd == "!tdl_pause" || LowerAscii(Trim(text.substr(cmd.size()))) == "pause";
				SetPaused(pause);
				ChatSay(pause ? "TDL paused" : "TDL resumed");
				return;
			}
			if (cmd == LowerAscii(IniValue("chatreplies", "HelpCommand"))) {
				SayHelp();  // anyone may ask
				return;
			}
			if (IniValue("twitch", "ChatAllowEveryone") != "1" && !privileged) {
				return;
			}
			const auto value = IniValue("chat", cmd);
			if (!value.empty()) {
				if (TDL_IsTwitchPaused() && !TDL_IsTwitchPauseHold()) {
					ChatSay("TDL paused");
					return;
				}
				const auto userId = chatterId;
				const auto now = Clock::now();
				ChatDecision decision = ChatDecision::kAllow;
				if (!userId.empty()) {
					std::lock_guard lk(g_userMtx);
					auto& state = g_users[userId];
					decision = CheckChat(state, text, now, IniInt("antispam", "IgnoreDuplicateSec", 5),
						IniInt("antispam", "UserCooldownSec", 20), privileged);
					for (auto it = state.seenCommands.begin(); it != state.seenCommands.end();) {
						it = now - it->second >= std::chrono::seconds(IniInt("antispam", "IgnoreDuplicateSec", 5)) ?
							state.seenCommands.erase(it) : ++it;
					}
					state.seenCommands[text] = now;
				}
				if (decision == ChatDecision::kDuplicate) return;
				if (decision == ChatDecision::kCooldown) {
					// ASVS 2.4.1: one warning per user per configured cooldown window.
					bool say = false;
					{
						std::lock_guard lk(g_userMtx);
						auto& state = g_users[userId];
						if (state.lastWarn.time_since_epoch().count() == 0 ||
							now - state.lastWarn >= std::chrono::seconds(IniInt("antispam", "UserCooldownSec", 20))) {
							state.lastWarn = now;
							say = true;
						}
					}
					if (say) ChatSay("@" + Str(ev, "chatter_user_name", "?") + ", too fast");
					return;
				}
				if (Submit(value, kSourcePoints, Str(ev, "chatter_user_name", "?"), cmd, {}, {}, userId, true, privileged) && !userId.empty()) {
					std::lock_guard lk(g_userMtx);
					g_users[userId].lastAccepted = now;
				}
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
		} else if (type == "channel.raid") {
			const int viewers = std::max(0, ev.value("viewers", 0));
			const auto who = Str(ev, "from_broadcaster_user_name", "Anonymous");
			const auto id = Str(ev, "from_broadcaster_user_id", "");
			HandleRaid(viewers, who, id);
		} else if (type == "channel.subscribe" || type == "channel.subscription.message" ||
			type == "channel.subscription.gift") {
			const bool gift = type == "channel.subscription.gift";
			if (type == "channel.subscribe" && ev.value("is_gift", false)) return;
			const bool anonymous = gift && ev.value("is_anonymous", false);
			const auto who = anonymous ? "Anonymous" : Str(ev, "user_name", "Anonymous");
			const auto id = anonymous ? "" : Str(ev, "user_id", "");
			SeeViewer(id, who);
			const char* key = gift ? "GiftSub" : type == "channel.subscription.message" ? "Resub" : "Sub";
			const char* fallback = gift ? "SUMMON_ANY" : "SYSTEM_BLESSING";
			const int count = gift && IniValue("events", "GiftSubPerGift") == "1" ?
				std::clamp(ev.value("total", 1), 1, std::clamp(IniInt("events", "GiftSubMax", 5), 1, 50)) : 1;
			for (int i = 0; i < count; ++i)
				Submit(IniValue("events", key, fallback), kSourceBits, who, key, {}, {}, id);
		} else if (type == "channel.hype_train.begin" || type == "channel.hype_train.progress") {
			const auto id = Str(ev, "id", "");
			const int level = std::max(0, ev.value("level", 0));
			if (type == "channel.hype_train.begin") {
				g_hypeLevels[id] = level;
				Submit(IniValue("events", "HypeTrainBegin", "WEATHER_STORM"), kSourceBits, "",
					"Hype train began");
			} else {
				const auto [it, inserted] = g_hypeLevels.emplace(id, level);
				if (!inserted && level > it->second) {
					it->second = level;
					Submit(IniValue("events", "HypeTrainLevel", "SUMMON_STRONG"), kSourceBits, "",
						"Hype train level " + std::to_string(level));
				}
			}
		}
	}

	// CreateRewards=1: add missing [Rewards] to the channel. Rewards created by this app can be refunded
	// automatically; ones made by hand in the Twitch dashboard cannot (Twitch API restriction).
	void EnsureRewards()
	{
		if (MockMode() || IniValue("twitch", "CreateRewards") != "1") {
			return;
		}
		const auto uid = UserId();
		const auto headers = "Authorization: Bearer " + Token() + "\r\nClient-Id: " + kClientId + "\r\n";
		const auto r = Http("GET", "https://api.twitch.tv/helix/channel_points/custom_rewards?broadcaster_id=" + uid, {}, headers);
		if (r.status != 200) {
			spdlog::info("Twitch: channel points not available ({}): rewards not created", r.status);  // no Affiliate/Partner
			return;
		}
		std::vector<std::string> existing;
		if (const auto j = ParseJson(r.body); j) {
			for (const auto& rw : j->value("data", json::array())) {
				existing.push_back(LowerAscii(rw.value("title", "")));
			}
		}
		for (const auto& title : RawSectionKeys("rewards")) {
			if (std::find(existing.begin(), existing.end(), LowerAscii(title)) != existing.end()) {
				spdlog::info("Twitch: reward '{}' already exists (refunds work only if TDL created it)", title);
				continue;
			}
			int cost = 1000;
			const auto c = IniValue("rewardcosts", title);
			std::from_chars(c.data(), c.data() + c.size(), cost);
			spdlog::info("Twitch: creating reward '{}' ({} points)", title, cost);
			Post({ "POST", "https://api.twitch.tv/helix/channel_points/custom_rewards?broadcaster_id=" + uid,
				json{ { "title", title }, { "cost", std::max(1, cost) } }.dump() });
		}
	}

	// ---------------------------------------------------------------- EventSub subscriptions

	bool SubscribeAll(const std::string& sessionId)
	{
		const auto uid = UserId();
		const json broadcaster = { { "broadcaster_user_id", uid } };
		struct Subscription { const char* type; const char* version; json condition; };
		const Subscription subs[] = {
			{ "channel.channel_points_custom_reward_redemption.add", "1", broadcaster },
			{ "channel.cheer", "1", broadcaster },
			{ "channel.poll.end", "1", broadcaster },
			{ "channel.chat.message", "1", { { "broadcaster_user_id", uid }, { "user_id", uid } } },
			{ "channel.raid", "1", { { "to_broadcaster_user_id", uid } } },
			{ "channel.subscribe", "1", broadcaster },
			{ "channel.subscription.message", "1", broadcaster },
			{ "channel.subscription.gift", "1", broadcaster },
			{ "channel.hype_train.begin", "2", broadcaster },
			{ "channel.hype_train.progress", "2", broadcaster },
		};

		const auto url = MockMode() ? "http://127.0.0.1:8080/eventsub/subscriptions"s :
		                              "https://api.twitch.tv/helix/eventsub/subscriptions"s;
		const auto headers = "Authorization: Bearer " + Token() + "\r\nClient-Id: " + kClientId +
		                     "\r\nContent-Type: application/json\r\n";

		int ok = 0;
		for (const auto& [type, version, condition] : subs) {
			const json body = { { "type", type }, { "version", version }, { "condition", condition },
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
						g_connected = true;
						static bool rewardsChecked = false;
						if (!rewardsChecked) {
							rewardsChecked = true;
							EnsureRewards();
						}
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
						SetToken({});
						break;
					}
				}

				// Twitch requires hourly token validation for long-lived sessions.
				if (!MockMode() && Clock::now() - g_lastValidate > std::chrono::hours(1) && Validate() == Auth::kInvalid) {
					SetToken({});
					break;
				}
			} catch (const json::exception& e) {
				spdlog::warn("Twitch: bad message ({}): {}", e.what(), msg);
			}
		}
		g_connected = false;
		CancelVote();
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
		std::thread(OutboxThread).detach();

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
#ifdef _DEBUG
	CheckAntiSpamLogic();
	CheckBatch3Logic();
	CheckRaidTiers();
#endif
	spdlog::info("Twitch: starting");
	{ std::lock_guard lk(g_statsMtx); g_stopping = false; g_statsBackupFailed = false; }
	LoadStats();
	g_voteStop = false;
	g_voteThread = std::thread(VoteThread);
	std::atexit(TDL_StopTwitch);
	TDL_SetOutcomeHook(OnOutcome);
	std::thread(TwitchThread).detach();  // WebSocket follows the process lifetime; the vote worker joins at exit.
}

bool TDL_IsTwitchPaused()
{
	(void)IniValue("twitch", "Paused");
	return g_paused.load();
}

bool TDL_IsTwitchPauseHold()
{
	(void)IniValue("twitch", "PauseMode");
	return g_pauseHold.load();
}

void TDL_StopTwitch()
{
	if (!g_started.exchange(false)) return;
	g_voteStop = true;
	g_voteCv.notify_all();
	if (g_voteThread.joinable()) g_voteThread.join();
	{ std::lock_guard lk(g_statsMtx); g_stopping = true; }  // ASVS 15.4.1: finish in-flight updates before the last save.
	SaveStats(true);
}

std::string TDL_GetTwitchStateJson()
{
	json state = { { "top", TopViewers() },
		{ "pauseMode", TDL_IsTwitchPauseHold() ? "hold" : "cancel" },
		{ "showTop", IniValue("overlay", "ShowTop", "1") != "0" },
		{ "showRecent", IniValue("overlay", "ShowRecent", "1") != "0" },
		{ "sound", IniValue("overlay", "Sound", "1") != "0" },
		{ "soundVolume", std::clamp(IniInt("overlay", "SoundVolume", 60), 0, 100) },
		{ "soundFile", IniValue("overlay", "SoundFile") },
		{ "recentMinutes", std::max(0, IniInt("overlay", "RecentMinutes", 10)) }, { "vote", nullptr } };
	{
		std::lock_guard lk(g_voteMtx);
		if (g_vote) {
			json options = json::array();
			for (const auto& o : g_vote->options)
				options.push_back({ { "label", o.label }, { "votes", o.votes } });
			state["vote"] = { { "options", std::move(options) },
				{ "secondsLeft", std::max(0, static_cast<int>(std::chrono::duration_cast<std::chrono::seconds>(
					g_vote->ends - Clock::now()).count()) + 1) } };
		}
	}
	return state.dump(-1, ' ', false, json::error_handler_t::replace);
}
