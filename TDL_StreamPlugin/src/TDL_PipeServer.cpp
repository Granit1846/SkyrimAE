// src/TDL_PipeServer.cpp
#include "TDL_PipeServer.h"
#include "TDL_Twitch.h"

#include <SKSE/SKSE.h>
#include <SKSE/API.h>
#include <SKSE/Events.h>
#include <SKSE/Interfaces.h>

#include <RE/T/TESDataHandler.h>
#include <RE/T/TESGlobal.h>
#include <RE/T/TESQuest.h>
#include <RE/V/VirtualMachine.h>
#include <RE/F/FunctionArguments.h>
#include <RE/P/PackUnpack.h>

#include <Windows.h>

#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif

#include <nlohmann/json.hpp>
#include <spdlog/spdlog.h>

#include <fstream>
#include <filesystem>
#include <unordered_map>


#include <algorithm>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

namespace
{
	using Clock = std::chrono::steady_clock;

	// ===== FORCE spec (agreed) =====
	static const double kForceDefaultIntervalSec = 0.85;
	static const double kForceMinIntervalSec = 0.75;
	static const double kForceMaxIntervalSec = 5.0;
	static const int kForceMaxCount = 50;

	// Teleport FORCE burst interval (hard clamp to avoid load-screen chaining)
	static const double kTeleportForceDefaultIntervalSec = 8.5;
	static const double kTeleportForceMinIntervalSec = 7.0;
	static const double kTeleportForceMaxIntervalSec = 10.0;

	static std::unordered_map<std::string, double> g_cfgActionCooldown;
	static std::unordered_map<std::string, double> g_cfgGroupDefault;

	static double g_forceDefault = 0.85;
	static double g_forceMin = 0.75;
	static double g_forceMax = 5.0;

	static double g_forceTeleportDefault = 8.5;
	static double g_forceTeleportMin = 7.0;
	static double g_forceTeleportMax = 10.0;

	static std::string Trim(const std::string& s)
	{
		size_t a = 0;
		while (a < s.size() && (s[a] == ' ' || s[a] == '\t' || s[a] == '\r' || s[a] == '\n')) a++;
		size_t b = s.size();
		while (b > a && (s[b - 1] == ' ' || s[b - 1] == '\t' || s[b - 1] == '\r' || s[b - 1] == '\n')) b--;
		return s.substr(a, b - a);
	}

	static bool IsCommentOrEmpty(const std::string& s)
	{
		if (s.empty()) return true;
		if (s[0] == ';' || s[0] == '#') return true;
		return false;
	}

	static bool TryParseDouble(const std::string& s, double& out)
	{
		try {
			out = std::stod(s);
			return true;
		}
		catch (...) {
			return false;
		}
	}


	static std::string ToLowerASCII(std::string s)
	{
		for (auto& ch : s) {
			if (ch >= 'A' && ch <= 'Z') {
				ch = static_cast<char>(ch - 'A' + 'a');
			}
		}
		return s;
	}

	static bool TryParseBoolOrDouble(const std::string& s, double& out)
	{
		const auto t = ToLowerASCII(Trim(s));
		if (t == "true" || t == "yes" || t == "on") {
			out = 1.0;
			return true;
		}
		if (t == "false" || t == "no" || t == "off") {
			out = 0.0;
			return true;
		}
		return TryParseDouble(t, out);
	}

	static std::unordered_map<std::string, std::unordered_map<std::string, std::string>>
	LoadIniKeyValues(const std::filesystem::path& iniPath)
	{
		std::unordered_map<std::string, std::unordered_map<std::string, std::string>> out;

		std::ifstream f(iniPath);
		if (!f.is_open()) {
			return out;
		}

		std::string section;
		std::string line;
		while (std::getline(f, line)) {
			line = Trim(line);
			if (IsCommentOrEmpty(line)) {
				continue;
			}

			if (line.size() >= 2 && line.front() == '[' && line.back() == ']') {
				section = ToLowerASCII(Trim(line.substr(1, line.size() - 2)));
				continue;
			}

			const auto eq = line.find('=');
			if (eq == std::string::npos) {
				continue;
			}

			const auto key = ToLowerASCII(Trim(line.substr(0, eq)));
			const auto val = Trim(line.substr(eq + 1));
			if (key.empty()) {
				continue;
			}

			out[section][key] = val;
		}

		return out;
	}

	static std::unordered_map<std::uint32_t, RE::TESGlobal*> g_globalsByLocalIDCache;

static RE::TESGlobal* LookupGlobalByLocalFormID_Cached(std::uint32_t localFormID)
{
	if (localFormID == 0) {
		return nullptr;
	}

	if (auto it = g_globalsByLocalIDCache.find(localFormID); it != g_globalsByLocalIDCache.end()) {
		return it->second;
	}

	auto* dh = RE::TESDataHandler::GetSingleton();
	if (!dh) {
		return nullptr;
	}

	// Primary plugin name (repo/install)
	if (auto* gv = dh->LookupForm<RE::TESGlobal>(localFormID, "TwitchDragonbornLegacy.esp")) {
		g_globalsByLocalIDCache.emplace(localFormID, gv);
		return gv;
	}

	// Fallback (older typo in some builds)
	if (auto* gv = dh->LookupForm<RE::TESGlobal>(localFormID, "TwichDragonbornLegacy.esp")) {
		g_globalsByLocalIDCache.emplace(localFormID, gv);
		return gv;
	}

	return nullptr;
}

	static void SetGlobalValue(RE::TESGlobal* gv, double v)
	{
		if (!gv) {
			return;
		}
		gv->value = static_cast<float>(v);
	}

	struct IniToGlobalMap
{
	const char* section;
	const char* key;
	std::uint32_t globalLocalFormID;
	double scale = 1.0;
};

static constexpr IniToGlobalMap kGameplayIniMap[] = {
	// NOTE:
	// - We deliberately bind globals by *local FormID* (lower 24 bits) + plugin filename.
	// - Runtime EditorID lookup is not reliable (EditorIDs are usually not present in-memory).

	// ===== CHAOS ===== (TDL_MCM_Chaos properties)
	{ "chaos", "backfirechance",      0x03CACD }, // TDL_Backfire_Chance
	{ "chaos", "backfireduration",    0x03CACC }, // TDL_Backfire_Duration
	{ "chaos", "shoutpushforce",      0x03CAD0 }, // TDL_ShoutPushForce
	{ "chaos", "shoutpushdelay",      0x03F9A2 }, // TDL_ShoutPushDelay
	{ "chaos", "knockbackforce",      0x03F99D }, // TDL_KnockbackForce
	{ "chaos", "knockbackcooldown",   0x03F99E }, // TDL_KnockbackCooldown
	{ "chaos", "knockbackradius",     0x03F99C }, // TDL_KnockbackRadius
	{ "chaos", "knockbackmeleedelay", 0x03F9A5 }, // TDL_KnockbackMeleeDelay
	{ "chaos", "knockbackbowdelay",   0x09B6CD }, // TDL_KnockbackBowDelay

	// ===== INVENTORY ===== (TDL_MCM_Inventory properties)
	{ "inventory", "scatterexactcount",    0x04B4C9 }, // TDL_InvSpam_RollsGV
	{ "inventory", "scattermincount",      0x04B4CA }, // TDL_InvSpam_CountMinGV
	{ "inventory", "scattermaxcount",      0x04B4CB }, // TDL_InvSpam_CountMaxGV
	{ "inventory", "scatterradius",        0x04B4D2 }, // TDL_InvSpam_RadiusGV
	{ "inventory", "dropbatchsize",        0x04B4CC }, // TDL_InvDrop_BatchSizeGV
	{ "inventory", "dropinterval",         0x04B4CD }, // TDL_InvDrop_IntervalGV
	{ "inventory", "droptimeout",          0x04B4C7 }, // TDL_InvDrop_Timeout
	{ "inventory", "protecttokensbyname",  0x04B4CE }, // TDL_InvProtectTokensByNameGV
	{ "inventory", "dropshowprogress",     0x04B4C8 }, // TDL_InvDrop_ShowProgress

	// ===== WRATH ===== (Wrath_* globals already match)
	{ "wrath", "totalbursts",        0x062B45 }, // Wrath_TotalBurstsGV
	{ "wrath", "interval",           0x062B46 }, // Wrath_EffectIntervalGV
	{ "wrath", "radius",             0x062B47 }, // Wrath_RadiusGV
	{ "wrath", "zoffset",            0x062B48 }, // Wrath_ZOffsetGV
	{ "wrath", "damagemin",          0x062B43 }, // Wrath_DamageMinGV
	{ "wrath", "damagemax",          0x062B44 }, // Wrath_DamageMaxGV
	{ "wrath", "firedamagemult",     0x062B4C }, // Wrath_FireDamageMultGV
	{ "wrath", "stormmagickamult",   0x062B50 }, // Wrath_StormMagickaMultGV
	{ "wrath", "froststaminamult",   0x062B4D }, // Wrath_FrostStaminaMultGV
	{ "wrath", "levelscale",         0x062B4F }, // Wrath_LevelScaleGV
	{ "wrath", "levelcap",           0x062B4E }, // Wrath_LevelCapGV
	{ "wrath", "shakechance",        0x062B49 }, // Wrath_ShakeChanceGV
	{ "wrath", "shakestrength",      0x062B4A }, // Wrath_ShakeStrengthGV
	{ "wrath", "shakeduration",      0x062B4B }, // Wrath_ShakeDurationGV

	// ===== HUNTER ===== (TDL_MCM_Hunter properties)
	{ "hunter", "duration",          0x030F92 }, // HunterDuration
	{ "hunter", "reaggrointerval",   0x030F93 }, // ReAggroInterval
	{ "hunter", "maxdistance",       0x030F94 }, // MaxDistance
	{ "hunter", "spawnoffset",       0x030F95 }, // SpawnOffset
	{ "hunter", "corpselifetime",    0x05FC7A }, // HunterCorpseLifetime

	// ===== GIGANT ===== (TDL_MCM_Gigant properties)
	{ "gigant", "sizeduration",      0x07441B }, // Gigant_SizeDurationGV
	{ "gigant", "speedduration",     0x07441C }, // Gigant_SpeedDurationGV
	{ "gigant", "scalebig",          0x0688EF }, // Gigant_ScaleBigGV
	{ "gigant", "damagebig",         0x0688F1 }, // Gigant_DamageBigGV
	{ "gigant", "scalesmall",        0x0688F0 }, // Gigant_ScaleSmallGV
	{ "gigant", "damagesmall",       0x0688F2 }, // Gigant_DamageSmallGV
	{ "gigant", "speedfast",         0x0688F3 }, // Gigant_SpeedMultGV
	{ "gigant", "speedslow",         0x0688F4 }, // Gigant_SpeedSlowGV

	// ===== COMEDY ===== (TDL_MCM_Comedy properties)
	{ "comedy", "fakeheroduration",		 0x04E3AA }, // FakeHeroDuration
	{ "comedy", "fakeheroactioninterval",		 0x05CDAC }, // FakeHeroActionInterval
	{ "comedy", "fakeherodamagemult",		 0x04E3AE }, // FakeHeroDamageMult
	{ "comedy", "fakeheropushforce",		 0x05CDAD }, // FakeHeroPushForce
	{ "comedy", "fakeheroshoutchance",		 0x05FC77 }, // FakeHeroShoutChance
	{ "comedy", "fakeherospellchance",		 0x05CDAB }, // FakeHeroSpellChance
	{ "comedy", "horrorduration",		 0x04E3AF }, // HorrorDuration
	{ "comedy", "horrorspawn",		 0x04E3B0 }, // HorrorSpawnDistance
	{ "comedy", "horrorteleport",		 0x04E3B1 }, // HorrorTeleportDistance
	{ "comedy", "horrormaxdist",		 0x04E3B2 }, // HorrorMaxDistance
	{ "comedy", "horrorhealth",		 0x04E3B3 }, // HorrorHealth
	{ "comedy", "arenawaves",		 0x04E3A2 }, // ArenaWaves
	{ "comedy", "arenaperwave",		 0x04E39F }, // ArenaPerWave
	{ "comedy", "arenainterval",		 0x04E3A1 }, // ArenaWaveInterval
	{ "comedy", "arenaradius",		 0x04E3A0 }, // ArenaSpawnRadius
	{ "comedy", "escortduration",		 0x065A1D }, // EscortDuration
};

	
	static void ReloadGameplayConfigFromIni_OnGameThread()
	{
		const std::filesystem::path iniPath =
			std::filesystem::current_path() / "Data" / "SKSE" / "Plugins" / "TDL_StreamPlugin.ini";

		const auto kv = LoadIniKeyValues(iniPath);
		if (kv.empty()) {
			spdlog::warn("Gameplay INI not found or empty: '{}'", iniPath.string());
			return;
		}

		int applied = 0;
		int missingGlobals = 0;

		g_globalsByLocalIDCache.clear();

		for (const auto& m : kGameplayIniMap) {
			auto sit = kv.find(m.section);
			if (sit == kv.end()) {
				continue;
			}

			auto kit = sit->second.find(m.key);
			if (kit == sit->second.end()) {
				continue;
			}

			double dv = 0.0;
			if (!TryParseBoolOrDouble(kit->second, dv)) {
				spdlog::warn("Gameplay INI parse failed: [{}] {}='{}'", m.section, m.key, kit->second);
				continue;
			}

			dv *= m.scale;

			auto* gv = LookupGlobalByLocalFormID_Cached(m.globalLocalFormID);
			if (!gv) {
				missingGlobals++;
				spdlog::warn("TESGlobal not found by FormID: 0x{:06X}", m.globalLocalFormID);
				continue;
			}

			SetGlobalValue(gv, dv);
			applied++;
		}

		spdlog::info("Gameplay config applied: updatedGlobals={}, missingGlobals={}, file='{}'",
			applied, missingGlobals, iniPath.string());
	}

	static void QueueReloadGameplayConfig()
	{
		if (auto* tasks = SKSE::GetTaskInterface(); tasks) {
			tasks->AddTask([] {
				ReloadGameplayConfigFromIni_OnGameThread();
				});
		}
		else {
			spdlog::warn("TaskInterface not available (cannot apply gameplay config)");
		}
	}
	static const char* GroupNameFromAction(const std::string& a)
	{
		if (a.rfind("SYSTEM_", 0) == 0) return "SYSTEM";
		if (a.rfind("WRATH_", 0) == 0) return "WRATH";
		if (a.rfind("SUMMON_", 0) == 0) return "SUMMON";
		if (a == "HUNTER_START") return "HUNTER";
		if (a.rfind("COMEDY_", 0) == 0) return "COMEDY";
		if (a.rfind("CHAOS_", 0) == 0) return "CHAOS";
		if (a.rfind("INVENTORY_", 0) == 0) return "INVENTORY";
		if (a.rfind("TELEPORT_", 0) == 0) return "TELEPORT";
		if (a.rfind("VIRUS_", 0) == 0) return "VIRUS";
		if (a.rfind("WEATHER_", 0) == 0) return "WEATHER";
		if (a.rfind("GIGANT_", 0) == 0) return "GIGANT";
		return "NONE";
	}

	static void LoadTDLConfigIni()
	{
		// defaults (safety net)
		g_cfgGroupDefault.clear();
		g_cfgActionCooldown.clear();

		// If user deletes keys, we still stay stable
		g_cfgGroupDefault["NONE"] = 0.0;
		g_cfgGroupDefault["SYSTEM"] = 20.0;
		g_cfgGroupDefault["WRATH"] = 60.0;
		g_cfgGroupDefault["SUMMON"] = 20.0;
		g_cfgGroupDefault["HUNTER"] = 120.0;
		g_cfgGroupDefault["COMEDY"] = 180.0;
		g_cfgGroupDefault["CHAOS"] = 60.0;
		g_cfgGroupDefault["INVENTORY"] = 60.0;
		g_cfgGroupDefault["TELEPORT"] = 20.0;
		g_cfgGroupDefault["VIRUS"] = 60.0;
		g_cfgGroupDefault["WEATHER"] = 30.0;
		g_cfgGroupDefault["GIGANT"] = 60.0;

		g_forceDefault = 0.85;
		g_forceMin = 0.75;
		g_forceMax = 5.0;

		g_forceTeleportDefault = 8.5;
		g_forceTeleportMin = 7.0;
		g_forceTeleportMax = 10.0;

		const std::filesystem::path iniPath =
			std::filesystem::current_path() / "Data" / "TDL" / "Config" / "TDL_Cooldowns.ini";

		std::ifstream f(iniPath);
		if (!f.is_open()) {
			spdlog::warn("Config INI not found: {}", iniPath.string());
			return;
		}

		spdlog::info("Loading config INI: {}", iniPath.string());

		std::string section;
		std::string line;

		while (std::getline(f, line)) {
			line = Trim(line);
			if (IsCommentOrEmpty(line)) continue;

			if (line.size() >= 3 && line.front() == '[' && line.back() == ']') {
				section = line.substr(1, line.size() - 2);
				section = Trim(section);
				continue;
			}

			const auto eq = line.find('=');
			if (eq == std::string::npos) continue;

			std::string key = Trim(line.substr(0, eq));
			std::string val = Trim(line.substr(eq + 1));

			double dv = 0.0;
			if (!TryParseDouble(val, dv)) {
				continue;
			}

			if (section == "GroupDefaults") {
				g_cfgGroupDefault[key] = dv;
			}
			else if (section == "ActionCooldowns") {
				g_cfgActionCooldown[key] = dv;
			}
			else if (section == "ForceBurst") {
				if (key == "Default") g_forceDefault = dv;
				else if (key == "Min") g_forceMin = dv;
				else if (key == "Max") g_forceMax = dv;
			}
			else if (section == "ForceBurst_Teleport") {
				if (key == "Default") g_forceTeleportDefault = dv;
				else if (key == "Min") g_forceTeleportMin = dv;
				else if (key == "Max") g_forceTeleportMax = dv;
			}
		}

		spdlog::info("Config loaded: ActionCooldowns={}, GroupDefaults={}",
			g_cfgActionCooldown.size(), g_cfgGroupDefault.size());
	}


	static bool IsTeleportForceAction(const std::string& a)
	{
		return (a == "TELEPORT_RANDOM_CITY" || a == "TELEPORT_RANDOM_DANGER");
	}

	static double ClampTeleportForceInterval(double v)
	{
		if (v < kTeleportForceMinIntervalSec) return kTeleportForceMinIntervalSec;
		if (v > kTeleportForceMaxIntervalSec) return kTeleportForceMaxIntervalSec;
		return v;
	}

	enum class CmdType : std::uint8_t
	{
		kNormal = 0,
		kForceBurst = 1
	};

	// Groups: used ONLY in DLL scheduler (Papyrus stays thin)
	enum Group : int
	{
		GROUP_NONE = 0,
		GROUP_SUMMON = 1,
		GROUP_HUNTER = 2,
		GROUP_COMEDY = 3,
		GROUP_CHAOS = 4,
		GROUP_INVENTORY = 5,
		GROUP_TELEPORT = 6,
		GROUP_VIRUS = 7,
		GROUP_WEATHER = 8,
		GROUP_GIGANT = 9,
		GROUP_WRATH = 10,
		GROUP_MAX = 10
	};

	struct NormalItem
	{
		std::string action;
		int source = 2;  // 1=beats,2=points,3=vote
		int group = GROUP_NONE;
		double cooldownSec = 0.0;
		std::uint64_t seq = 0;
		TDL_Origin origin;
		bool forceSingle = false;
	};

	struct ForceBurstItem
	{
		std::string action;
		int count = 1;
		double intervalSec = kForceDefaultIntervalSec;
		std::uint64_t seq = 0;
		TDL_Origin origin;
	};

	struct Command
	{
		CmdType type{ CmdType::kNormal };
		NormalItem normal{};
		ForceBurstItem burst{};
	};

	static std::atomic_bool g_running{ false };

	static std::mutex g_mtx;
	static std::condition_variable g_cv;
	static std::deque<Command> g_cmds;
	static bool g_twitchPaused = false;
	static bool g_twitchPauseHold = false;
	static std::atomic_uint64_t g_seq{ 0 };  // ParseLineToCommand runs on the pipe and Twitch threads

	// Normal scheduling state
	static Clock::time_point g_groupReady[GROUP_MAX + 1]{};
	static Clock::time_point g_globalReady{};

	// Overlay / Twitch feedback (guarded by g_mtx)
	struct RecentItem
	{
		std::string text;
		Clock::time_point at;
		uint64_t id;
	};
	static std::deque<RecentItem> g_recent;
	static uint64_t g_recentId = 0;
	static std::atomic<TDL_OutcomeHook> g_outcomeHook{ nullptr };

	static void RememberRecent(const std::string& notice)
	{
		if (notice.empty()) {
			return;
		}
		std::lock_guard lk(g_mtx);
		g_recent.push_front({ notice, Clock::now(), ++g_recentId });
		if (g_recent.size() > 8) {
			g_recent.pop_back();
		}
	}

	static void ReportOutcome(const TDL_Origin& origin, bool fired)
	{
		if (auto hook = g_outcomeHook.load(); hook) {
			hook(origin, fired);
		}
	}

	// Seconds until a group may fire again (cooldown and the global gap), 0 if ready.
	static double SecondsUntilReady(int group, Clock::time_point now)
	{
		auto at = g_groupReady[group];
		if (g_globalReady > at) {
			at = g_globalReady;
		}
		return at > now ? std::chrono::duration<double>(at - now).count() : 0.0;
	}

	static int ClampSource(int s)
	{
		if (s < 1) return 1;
		if (s > 3) return 3;
		return s;
	}

	static std::size_t GetNormalQueueCapForGroup(int group) noexcept
	{
		// Default: 15 pending per group.
		// Special groups: VIRUS/COMEDY/INVENTORY -> 8 pending per group.
		if (group == GROUP_VIRUS || group == GROUP_COMEDY || group == GROUP_INVENTORY) {
			return 8;
		}
		return 15;
	}

	static bool StartsWith(const std::string& s, const char* prefix)
	{
		return s.rfind(prefix, 0) == 0;
	}

	static int GetGroupForAction(const std::string& a)
	{
		if (StartsWith(a, "SYSTEM_")) return GROUP_NONE;
		if (StartsWith(a, "WRATH_")) return GROUP_WRATH;
		if (StartsWith(a, "SUMMON_")) return GROUP_SUMMON;
		if (a == "HUNTER_START") return GROUP_HUNTER;
		if (StartsWith(a, "COMEDY_")) return GROUP_COMEDY;
		if (StartsWith(a, "CHAOS_")) return GROUP_CHAOS;
		if (StartsWith(a, "INVENTORY_")) return GROUP_INVENTORY;
		if (StartsWith(a, "TELEPORT_")) return GROUP_TELEPORT;
		if (StartsWith(a, "VIRUS_")) return GROUP_VIRUS;
		if (StartsWith(a, "WEATHER_")) return GROUP_WEATHER;
		if (StartsWith(a, "GIGANT_")) return GROUP_GIGANT;
		return GROUP_NONE;
	}

	// Cooldowns are NOT in MCM by design. Keep in sync with your Papyrus table.
	static double GetCooldownForAction(const std::string& a)
	{
		if (auto it = g_cfgActionCooldown.find(a); it != g_cfgActionCooldown.end()) {
			return it->second;
		}

		const char* gname = GroupNameFromAction(a);
		if (auto itg = g_cfgGroupDefault.find(gname); itg != g_cfgGroupDefault.end()) {
			return itg->second;
		}

		return 20.0;  // last resort
	}


	// FORCE allow-list (burst)
	static bool IsForceBurstAllowed(const std::string& a)
	{
		if (StartsWith(a, "SUMMON_")) return true;
		if (a == "INVENTORY_SCATTER") return true;
		if (a == "TELEPORT_RANDOM_CITY") return true;
		if (a == "TELEPORT_RANDOM_DANGER") return true;
		if (a == "VIRUS_DISEASE") return true;
		return false;
	}

	// FORCE per-action caps (burst)
	static int GetForceBurstMaxCount(const std::string& a)
	{
		if (StartsWith(a, "SUMMON_")) return 50;
		if (a == "INVENTORY_SCATTER") return 10;
		if (a == "TELEPORT_RANDOM_CITY") return 5;
		if (a == "TELEPORT_RANDOM_DANGER") return 5;
		if (a == "VIRUS_DISEASE") return 15;
		return 0;
	}

	// FORCE1 allow-list (single)
	static bool IsForceSingleAllowed(const std::string& a)
	{
		return (a == "SYSTEM_HEALING" || a == "SYSTEM_BLESSING" || a == "WRATH_11" || a == "WRATH_12" || a == "WRATH_13");
	}

	// Direct call instead of a ModEvent: RegisterForModEvent (done in OnInit) is not persisted in saves,
	// so after loading a game the mod event reached no listener.
	static constexpr std::uint32_t kStreamControllerQuestID = 0x0A07CE;  // TDL_StreamController quest

	static void SendTDLSubmitAction_OnGameThread(std::string actionID, int sourceType)
	{
		auto* quest = RE::TESDataHandler::GetSingleton()->LookupForm<RE::TESQuest>(kStreamControllerQuestID, "TwitchDragonbornLegacy.esp");
		auto* vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
		if (!quest || !vm) {
			spdlog::warn("TDL_StreamController quest or Papyrus VM not available");
			return;
		}

		const auto handle = vm->GetObjectHandlePolicy()->GetHandleForObject(quest->GetFormType(), quest);
		RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> callback;
		auto* args = RE::MakeFunctionArguments(std::move(actionID), static_cast<std::int32_t>(sourceType));
		if (!vm->DispatchMethodCall(handle, "TDL_StreamController", "SubmitAction", args, callback)) {
			spdlog::warn("Papyrus call TDL_StreamController.SubmitAction failed");
		}
	}

	// Papyrus Debug.Notification: no extra Address Library IDs needed, same path as SubmitAction
	static void ShowNotification_OnGameThread(std::string text)
	{
		if (auto* vm = RE::BSScript::Internal::VirtualMachine::GetSingleton(); vm) {
			RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> callback;
			vm->DispatchStaticCall("Debug", "Notification", RE::MakeFunctionArguments(std::move(text)), callback);
		}
	}

	// Skyrim shows Papyrus strings in the system ANSI code page (the mod's .psc files are cp1251); notices are UTF-8.
	static std::string ToGameText(const std::string& utf8)
	{
		const int wn = MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), nullptr, 0);
		std::wstring w(static_cast<size_t>(wn), L'\0');
		MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), w.data(), wn);
		const int n = WideCharToMultiByte(CP_ACP, 0, w.data(), wn, nullptr, 0, nullptr, nullptr);
		std::string out(static_cast<size_t>(n), '\0');
		WideCharToMultiByte(CP_ACP, 0, w.data(), wn, out.data(), n, nullptr, nullptr);
		return out;  // shortcut: chars outside the ANSI code page (emoji) become '?'
	}

	static void DispatchAction(std::string action, int source, const std::string& noticeUtf8 = {})
	{
		if (auto* tasks = SKSE::GetTaskInterface(); tasks) {
			tasks->AddTask([a = std::move(action), s = source, n = ToGameText(noticeUtf8)]() mutable {
				if (!n.empty()) {
					ShowNotification_OnGameThread(std::move(n));
				}
				SendTDLSubmitAction_OnGameThread(std::move(a), s);
				});
		}
		else {
			spdlog::warn("TaskInterface not available");
		}
	}

	static std::vector<std::string> SplitPipe(const std::string& s)
	{
		std::vector<std::string> out;
		size_t start = 0;
		for (;;) {
			size_t pos = s.find('|', start);
			if (pos == std::string::npos) {
				out.emplace_back(s.substr(start));
				break;
			}
			out.emplace_back(s.substr(start, pos - start));
			start = pos + 1;
		}
		return out;
	}

	static double ClampForceInterval(double v)
	{
		if (v < kForceMinIntervalSec) return kForceMinIntervalSec;
		if (v > kForceMaxIntervalSec) return kForceMaxIntervalSec;
		return v;
	}

	static std::optional<Command> ParseLineToCommand(const std::string& line)
	{
		auto parts = SplitPipe(line);
		if (parts.empty()) {
			return std::nullopt;
		}

		// Special internal command (handled in DLL, not sent to Papyrus)
		// tdl_send.exe NORMAL SYSTEM_RELOAD_CONFIG 2  ->  "SYSTEM_RELOAD_CONFIG|2"
		if (parts[0] == "SYSTEM_RELOAD_CONFIG") {
			spdlog::info("SYSTEM_RELOAD_CONFIG requested");
			QueueReloadGameplayConfig();
			return std::nullopt;
		}


		// FORCE burst: FORCE|ACTION|COUNT or FORCE|ACTION|COUNT|INTERVAL
		if (parts[0] == "FORCE") {
			if (parts.size() < 3) {
				return std::nullopt;
			}

			const std::string& action = parts[1];
			if (!IsForceBurstAllowed(action)) {
				spdlog::warn("FORCE rejected: action '{}' not allowed", action);
				return std::nullopt;
			}

			int count = 0;
			try {
				count = std::stoi(parts[2]);
			}
			catch (...) {
				return std::nullopt;
			}
			if (count <= 0) {
				return std::nullopt;
			}

			// Apply limits
			if (count > kForceMaxCount) count = kForceMaxCount;
			const int perActionCap = GetForceBurstMaxCount(action);
			if (perActionCap > 0 && count > perActionCap) {
				count = perActionCap;
			}

			double interval = 0.0;
			const bool hasInterval = (parts.size() >= 4 && !parts[3].empty());

			if (hasInterval) {
				try {
					interval = std::stod(parts[3]);
				}
				catch (...) {
					interval = 0.0;
				}
			}

			if (IsTeleportForceAction(action)) {
				// teleport burst: always 7–10 sec, default 8.5 sec
				if (interval <= 0.0) {
					interval = kTeleportForceDefaultIntervalSec;
				}
				interval = ClampTeleportForceInterval(interval);
			}
			else {
				// normal burst: 0.75–5 sec, default 0.85 sec
				if (interval <= 0.0) {
					interval = kForceDefaultIntervalSec;
				}
				interval = ClampForceInterval(interval);
			}

			Command cmd{};
			cmd.type = CmdType::kForceBurst;
			cmd.burst.action = action;
			cmd.burst.count = count;
			cmd.burst.intervalSec = interval;
			cmd.burst.seq = ++g_seq;
			return cmd;
		}

		// FORCE single: FORCE1|ACTION  (no SOURCE per your final decision)
		if (parts[0] == "FORCE1") {
			if (parts.size() < 2) {
				return std::nullopt;
			}
			const std::string& action = parts[1];
			if (!IsForceSingleAllowed(action)) {
				spdlog::warn("FORCE1 rejected: action '{}' not allowed", action);
				return std::nullopt;
			}

			// Direct dispatch (no queue, no cooldown)
			spdlog::info("FORCE1 dispatch: '{}'", action);
			DispatchAction(action, 1);
			return std::nullopt;
		}

		// Normal: ACTION|SOURCE
		if (parts.size() < 2) {
			return std::nullopt;
		}

		Command cmd{};
		cmd.type = CmdType::kNormal;
		cmd.normal.action = parts[0];

		int source = 2;
		try {
			source = std::stoi(parts[1]);
		}
		catch (...) {
			return std::nullopt;
		}
		source = ClampSource(source);

		cmd.normal.source = source;
		cmd.normal.group = GetGroupForAction(cmd.normal.action);
		cmd.normal.cooldownSec = GetCooldownForAction(cmd.normal.action);
		cmd.normal.seq = ++g_seq;

		return cmd;
	}

	// Per-group bounded queue in DLL:
	// - default: up to 15 pending Normal items per group
	// - groups VIRUS/COMEDY/INVENTORY: up to 8 pending Normal items per group
	// If the group is full, we replace the "worst" queued item in that group ONLY if the new item has higher priority.
	// Priority: source 1 (beats) > 2 (points) > 3 (vote).
	static TDL_SubmitInfo EnqueueNormalOrReplaceByGroup(NormalItem&& item)
	{
		TDL_SubmitInfo info{};
		std::optional<TDL_Origin> evicted;
		{
		std::lock_guard lk(g_mtx);

		const std::size_t cap = GetNormalQueueCapForGroup(item.group);
		const int group = item.group;
		const int source = item.source;
		const std::uint64_t seq = item.seq;

		std::size_t count = 0;
		std::size_t worstIdx = static_cast<std::size_t>(-1);
		int worstSource = -1;
		std::uint64_t worstSeq = 0;

		for (std::size_t i = 0; i < g_cmds.size(); ++i) {
			auto& c = g_cmds[i];
			if (c.type != CmdType::kNormal) {
				continue;
			}
			if (c.normal.group != item.group) {
				continue;
			}

			++count;

			// Eviction candidate: lowest priority (max source); if tie, newest (max seq).
			if (c.normal.source > worstSource || (c.normal.source == worstSource && c.normal.seq > worstSeq)) {
				worstSource = c.normal.source;
				worstSeq = c.normal.seq;
				worstIdx = i;
			}
		}

		if (count >= cap) {
			if (worstIdx != static_cast<std::size_t>(-1) && item.source < worstSource) {
				spdlog::info("Queue: REPLACE (cap {}) group={} '{}' src={} (was '{}' src={})",
					cap, item.group, item.action, item.source, g_cmds[worstIdx].normal.action, g_cmds[worstIdx].normal.source);
				evicted = std::move(g_cmds[worstIdx].normal.origin);
				g_cmds[worstIdx].normal = std::move(item);
				info.accepted = true;
				g_cv.notify_one();
			}
			else {
				spdlog::info("Queue: DROP (cap {}) group={} '{}' src={}", cap, item.group, item.action, item.source);
			}
		}
		else {
			Command cmd{};
			cmd.type = CmdType::kNormal;
			cmd.normal = std::move(item);
			g_cmds.push_back(std::move(cmd));
			spdlog::info("Queue: PUSH group={} '{}' src={} ({} / {})",
				g_cmds.back().normal.group, g_cmds.back().normal.action, g_cmds.back().normal.source, (count + 1), cap);
			info.accepted = true;
			g_cv.notify_one();
		}

		if (info.accepted) {
			// Rough ETA from the queue as it is now: group cooldown + same-group items that fire first (source, seq)
			double eta = SecondsUntilReady(group, Clock::now());
			int ahead = 0;
			for (const auto& c : g_cmds) {
				if (c.type == CmdType::kNormal && c.normal.group == group &&
					(c.normal.source < source || (c.normal.source == source && c.normal.seq < seq))) {
					eta += c.normal.cooldownSec;
					++ahead;
				}
			}
			info.position = ahead + 1;
			info.etaSec = static_cast<int>(eta + 0.5);
		}
		}
		if (evicted) {
			ReportOutcome(*evicted, false);  // outside the lock: the hook may do slow work
		}
		return info;
	}

	static TDL_SubmitInfo EnqueueCommand(Command&& cmd)
	{
		if (cmd.type == CmdType::kNormal) {
			return EnqueueNormalOrReplaceByGroup(std::move(cmd.normal));
		}

		// ForceBurst: push as a command, does not replace normal-by-group; bursts go first
		{
			std::lock_guard lk(g_mtx);
			g_cmds.push_back(std::move(cmd));
		}
		g_cv.notify_one();
		return { true, 1, 0 };
	}

	static void SchedulerThreadProc()
	{
		const auto globalMinGap = std::chrono::milliseconds(250);

		while (g_running.load()) {
			Command next{};
			bool have = false;
			(void)TDL_IsTwitchPaused();  // reload config before taking the queue lock

			{
				std::unique_lock lk(g_mtx);
				if (g_cmds.empty()) g_cv.wait_for(lk, std::chrono::milliseconds(200));

				if (!g_running.load()) {
					break;
				}
				if (g_cmds.empty()) {
					continue;
				}

				const auto now = Clock::now();
				const bool hold = g_twitchPaused && g_twitchPauseHold;

				// 1) FORCE burst: takes precedence, runs as one block
				for (size_t i = 0; i < g_cmds.size(); i++) {
					if (g_cmds[i].type == CmdType::kForceBurst && !(hold && g_cmds[i].burst.origin.twitch)) {
						next = std::move(g_cmds[i]);
						g_cmds.erase(g_cmds.begin() + static_cast<std::ptrdiff_t>(i));
						have = true;
						break;
					}
				}

				// 2) Normal: best eligible by (source, seq) and ready by group cooldown + global gap
				if (!have) {
					size_t bestIdx = static_cast<size_t>(-1);
					int bestSource = 999;
					std::uint64_t bestSeq = 0;
					Clock::time_point wakeAt = now + std::chrono::seconds(60);

					for (size_t i = 0; i < g_cmds.size(); i++) {
						auto& c = g_cmds[i];
						if (c.type != CmdType::kNormal) {
							continue;
						}
						if (hold && c.normal.origin.twitch) continue;

						auto canAt = g_groupReady[c.normal.group];
						if (canAt.time_since_epoch().count() == 0) {
							canAt = Clock::time_point::min();
						}
						if (g_globalReady.time_since_epoch().count() != 0 && g_globalReady > canAt) {
							canAt = g_globalReady;
						}

						if (canAt <= now) {
							if (c.normal.source < bestSource || (c.normal.source == bestSource && c.normal.seq < bestSeq)) {
								bestSource = c.normal.source;
								bestSeq = c.normal.seq;
								bestIdx = i;
							}
						}
						else {
							if (canAt < wakeAt) {
								wakeAt = canAt;
							}
						}
					}

					if (bestIdx == static_cast<size_t>(-1)) {
						// Wait until the earliest cooldown expires OR a new command arrives (notify_one).
						if (hold) g_cv.wait_for(lk, std::chrono::milliseconds(200));
						else g_cv.wait_until(lk, wakeAt);
						continue;
					}

					next = std::move(g_cmds[bestIdx]);
					g_cmds.erase(g_cmds.begin() + static_cast<std::ptrdiff_t>(bestIdx));
					have = true;

				}
			}

			if (!have) {
				continue;
			}

			const auto& origin = next.type == CmdType::kNormal ? next.normal.origin : next.burst.origin;

			if (next.type == CmdType::kNormal) {
				bool held = false;
				bool canceled = false;
				{
					std::lock_guard lk(g_mtx);
					// ASVS 15.4.2: pause decision and dispatch handoff share the queue lock.
					if (origin.twitch && g_twitchPaused) {
						if (g_twitchPauseHold) { g_cmds.push_front(std::move(next)); held = true; }
						else canceled = true;
					} else {
						if (!next.normal.forceSingle) {
							const auto now2 = Clock::now();
							g_groupReady[next.normal.group] = now2 + std::chrono::milliseconds(static_cast<int>(next.normal.cooldownSec * 1000.0));
							g_globalReady = now2 + globalMinGap;
						}
						spdlog::info("Dispatch: group={} '{}' src={} cd={}s",
							next.normal.group, next.normal.action, next.normal.source, next.normal.cooldownSec);
						DispatchAction(std::move(next.normal.action), next.normal.forceSingle ? 1 : next.normal.source, origin.notice);
					}
				}
				if (!held) {
					if (!canceled) RememberRecent(origin.notice.empty() ? origin.trigger : origin.notice);
					ReportOutcome(origin, !canceled);
				}
				continue;
			}

			// FORCE burst: ignore normal cooldowns; sequentially dispatch with interval
			spdlog::warn("FORCE burst start: '{}' x{} interval={}s",
				next.burst.action, next.burst.count, next.burst.intervalSec);

			bool heldBurst = false;
			int dispatched = 0;
			for (int i = 0; i < next.burst.count; i++) {
				{
					std::lock_guard lk(g_mtx);
					if (!g_running.load()) break;
					if (origin.twitch && g_twitchPaused) {
						if (g_twitchPauseHold) {
							// ASVS 2.3.1: keep remaining steps and their slot queued.
							next.burst.count -= i;
							if (i) next.burst.origin.notice.clear();
							heldBurst = true;
							g_cmds.push_front(std::move(next));
						}
						break;
					}
					DispatchAction(next.burst.action, 1, i == 0 ? origin.notice : std::string{});
					++dispatched;
				}
				if (i + 1 < next.burst.count) {
					std::unique_lock lk(g_mtx);
					g_cv.wait_for(lk, std::chrono::milliseconds(static_cast<int>(next.burst.intervalSec * 1000.0)), [&] {
						return !g_running.load() || (origin.twitch && g_twitchPaused);
					});
				}
			}

			if (!heldBurst) {
				if (dispatched == next.burst.count) RememberRecent(origin.notice.empty() ? origin.trigger : origin.notice);
				ReportOutcome(origin, dispatched == next.burst.count);
				spdlog::warn("FORCE burst done: '{}'", next.burst.action);
			}
		}
	}

	static void PipeThreadProc()
	{
		while (g_running.load()) {
			HANDLE hPipe = CreateNamedPipeW(
				L"\\\\.\\pipe\\TDL_Stream",
				PIPE_ACCESS_INBOUND,
				PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
				1, 0, 4096, 0, nullptr);

			if (hPipe == INVALID_HANDLE_VALUE) {
				spdlog::error("CreateNamedPipe failed: {}", GetLastError());
				std::this_thread::sleep_for(std::chrono::milliseconds(300));
				continue;
			}

			BOOL connected = ConnectNamedPipe(hPipe, nullptr) ? TRUE : (GetLastError() == ERROR_PIPE_CONNECTED);
			if (!connected) {
				CloseHandle(hPipe);
				continue;
			}

			spdlog::info("Pipe client connected");

			std::string carry;
			char buf[512]{};
			DWORD read = 0;

			while (g_running.load() && ReadFile(hPipe, buf, static_cast<DWORD>(sizeof(buf)), &read, nullptr) && read > 0) {
				carry.append(buf, buf + read);

				size_t start = 0;
				for (;;) {
					const size_t nl = carry.find('\n', start);
					if (nl == std::string::npos) {
						carry.erase(0, start);
						break;
					}

					std::string line = carry.substr(start, nl - start);
					start = nl + 1;

					if (!line.empty() && line.back() == '\r') {
						line.pop_back();
					}
					if (line.empty()) {
						continue;
					}

					auto cmd = ParseLineToCommand(line);
					if (!cmd) {
						continue;
					}

					if (cmd->type == CmdType::kNormal) {
						spdlog::info("Pipe recv: '{}'|{}", cmd->normal.action, cmd->normal.source);
					}
					else {
						spdlog::info("Pipe recv: FORCE '{}' x{} interval={}s", cmd->burst.action, cmd->burst.count, cmd->burst.intervalSec);
					}

					EnqueueCommand(std::move(*cmd));
				}
			}

			DisconnectNamedPipe(hPipe);
			CloseHandle(hPipe);
			spdlog::info("Pipe client disconnected");
		}
	}

	static void UnblockConnect()
	{
		// Wake ConnectNamedPipe on shutdown
		HANDLE h = CreateFileW(L"\\\\.\\pipe\\TDL_Stream", GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0, nullptr);
		if (h != INVALID_HANDLE_VALUE) {
			CloseHandle(h);
		}
	}
}

void TDL_StartPipeServer()
{
	if (g_running.exchange(true)) {
		return;  // already running
	}

	// reset sched state
	for (auto& t : g_groupReady) {
		t = Clock::time_point{};
	}
	g_globalReady = Clock::time_point{};

	// load INI config (cooldowns, force intervals)
	LoadTDLConfigIni();

	// apply gameplay INI (TDL_StreamPlugin.ini -> TESGlobal)
	QueueReloadGameplayConfig();

	spdlog::info("Starting Pipe/Scheduler...");

	// Detached: no shutdown hook exists, and a joinable static std::thread calls std::terminate at process exit
	std::thread(SchedulerThreadProc).detach();
	std::thread(PipeThreadProc).detach();

	spdlog::info("Pipe/Scheduler started");
}

void TDL_StopPipeServer()
{
	if (!g_running.exchange(false)) {
		return;
	}

	g_cv.notify_all();
	UnblockConnect();


	std::vector<TDL_Origin> canceled;
	{
		std::lock_guard lk(g_mtx);
		for (const auto& cmd : g_cmds) {
			canceled.push_back(cmd.type == CmdType::kNormal ? cmd.normal.origin : cmd.burst.origin);
		}
		g_cmds.clear();
	}
	for (const auto& origin : canceled) ReportOutcome(origin, false);

	spdlog::info("Pipe/Scheduler stopped");
}

void TDL_WakeScheduler()
{
	g_cv.notify_all();
}

void TDL_SetTwitchPauseState(bool paused, bool hold)
{
	std::vector<TDL_Origin> canceled;
	{
		std::lock_guard lk(g_mtx);
		if (g_twitchPaused && g_twitchPauseHold && !hold) {
			for (auto it = g_cmds.begin(); it != g_cmds.end();) {
				const auto& origin = it->type == CmdType::kNormal ? it->normal.origin : it->burst.origin;
				if (origin.twitch) {
					canceled.push_back(origin);
					it = g_cmds.erase(it);
				} else ++it;
			}
		}
		g_twitchPaused = paused;
		g_twitchPauseHold = hold;
	}
	for (const auto& origin : canceled) ReportOutcome(origin, false);
	g_cv.notify_all();
}

void TDL_ReloadGameplayConfig()
{
	QueueReloadGameplayConfig();
}

TDL_SubmitInfo TDL_SubmitLine(const std::string& line, const TDL_Origin& origin)
{
	// FORCE1 fires at once inside the parser (no queue), so report it as fired here, not as rejected
	if (line.rfind("FORCE1|", 0) == 0) {
		const auto action = line.substr(7);
		if (!IsForceSingleAllowed(action)) {
			return {};
		}
		(void)TDL_IsTwitchPaused();  // reload config before the queue gate
		{
			std::lock_guard lk(g_mtx);
			// ASVS 15.4.2: FORCE1 uses the same pause gate as scheduled actions.
			if (origin.twitch && g_twitchPaused) {
				if (!g_twitchPauseHold) return {};
				Command cmd{};
				cmd.normal.action = action;
				cmd.normal.source = 1;
				cmd.normal.group = GetGroupForAction(action);
				cmd.normal.seq = ++g_seq;
				cmd.normal.origin = origin;
				cmd.normal.forceSingle = true;
				g_cmds.push_back(std::move(cmd));
				g_cv.notify_one();
				return { true, 1, 0 };
			}
			spdlog::info("FORCE1 dispatch: '{}'", action);
			DispatchAction(action, 1, origin.notice);
		}
		RememberRecent(origin.notice.empty() ? origin.trigger : origin.notice);
		ReportOutcome(origin, true);
		return { true, 1, 0 };
	}

	auto cmd = ParseLineToCommand(line);
	if (!cmd) {
		return {};
	}
	cmd->normal.origin = origin;
	cmd->burst.origin = origin;
	spdlog::info("Submit: '{}'", line);
	return EnqueueCommand(std::move(*cmd));
}

void TDL_SetOutcomeHook(TDL_OutcomeHook hook)
{
	g_outcomeHook = hook;
}

void TDL_Notify(const std::string& text)
{
	if (auto* tasks = SKSE::GetTaskInterface(); tasks) {
		tasks->AddTask([message = ToGameText(text)] { ShowNotification_OnGameThread(message); });
	}
}

std::string TDL_GetStateJson()
{
	const bool paused = TDL_IsTwitchPaused();
	struct Row
	{
		const NormalItem* item;
		double eta;
	};

	nlohmann::json state;
	std::lock_guard lk(g_mtx);
	const auto now = Clock::now();

	// Firing order within a group is by (source, seq); groups run in parallel, so sort all rows by ETA.
	std::vector<const NormalItem*> items;
	nlohmann::json queue = nlohmann::json::array();
	for (const auto& c : g_cmds) {
		if (c.type == CmdType::kForceBurst) {
			queue.push_back({ { "who", c.burst.origin.who }, { "trigger", c.burst.origin.trigger }, { "eta", 0 } });
		} else {
			items.push_back(&c.normal);
		}
	}
	std::sort(items.begin(), items.end(), [](auto* a, auto* b) {
		return a->source != b->source ? a->source < b->source : a->seq < b->seq;
	});
	std::vector<Row> rows;
	double groupEta[GROUP_MAX + 1]{};
	for (int g = 0; g <= GROUP_MAX; ++g) {
		groupEta[g] = SecondsUntilReady(g, now);
	}
	for (auto* it : items) {
		rows.push_back({ it, groupEta[it->group] });
		groupEta[it->group] += it->cooldownSec;
	}
	std::stable_sort(rows.begin(), rows.end(), [](const Row& a, const Row& b) { return a.eta < b.eta; });
	for (const auto& r : rows) {
		queue.push_back({ { "who", r.item->origin.who }, { "trigger", r.item->origin.trigger.empty() ? r.item->action : r.item->origin.trigger },
			{ "eta", static_cast<int>(r.eta + 0.5) } });
	}

	nlohmann::json recent = nlohmann::json::array();
	state.update(nlohmann::json::parse(TDL_GetTwitchStateJson()));
	const int recentMinutes = state.value("recentMinutes", 10);
	for (const auto& r : g_recent) {
		if (recentMinutes > 0 && now - r.at > std::chrono::minutes(recentMinutes)) continue;
		recent.push_back({ { "text", r.text }, { "ago", static_cast<int>(std::chrono::duration<double>(now - r.at).count()) }, { "id", r.id } });
	}

	state["paused"] = paused;
	state["queue"] = std::move(queue);
	state["recent"] = std::move(recent);
	return state.dump(-1, ' ', false, nlohmann::json::error_handler_t::replace);
}

TDL_IniData TDL_LoadIni(const std::filesystem::path& iniPath)
{
	return LoadIniKeyValues(iniPath);
}
