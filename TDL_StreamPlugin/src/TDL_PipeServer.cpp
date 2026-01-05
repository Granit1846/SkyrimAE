// src/TDL_PipeServer.cpp
#include "TDL_PipeServer.h"

#include <SKSE/SKSE.h>
#include <SKSE/API.h>
#include <SKSE/Events.h>
#include <SKSE/Interfaces.h>

#include <Windows.h>

#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif

#include <spdlog/spdlog.h>

#include <fstream>
#include <filesystem>
#include <unordered_map>


#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <mutex>
#include <optional>
#include <string>
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
	};

	struct ForceBurstItem
	{
		std::string action;
		int count = 1;
		double intervalSec = kForceDefaultIntervalSec;
		std::uint64_t seq = 0;
	};

	struct Command
	{
		CmdType type{ CmdType::kNormal };
		NormalItem normal{};
		ForceBurstItem burst{};
	};

	static std::atomic_bool g_running{ false };
	static std::thread g_pipeThread;
	static std::thread g_schedThread;

	static std::mutex g_mtx;
	static std::condition_variable g_cv;
	static std::deque<Command> g_cmds;
	static std::uint64_t g_seq = 0;

	// Normal scheduling state
	static Clock::time_point g_groupReady[GROUP_MAX + 1]{};
	static Clock::time_point g_globalReady{};

	static int ClampSource(int s)
	{
		if (s < 1) return 1;
		if (s > 3) return 3;
		return s;
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
		return (a == "SYSTEM_HEALING" || a == "WRATH_11" || a == "WRATH_12" || a == "WRATH_13");
	}

	static void SendTDLSubmitAction_OnGameThread(std::string actionID, int sourceType)
	{
		auto* src = SKSE::GetModCallbackEventSource();
		if (!src) {
			spdlog::warn("ModCallbackEventSource not available");
			return;
		}

		SKSE::ModCallbackEvent ev{};
		ev.eventName = "TDL_SubmitAction";
		ev.strArg = actionID.c_str();
		ev.numArg = static_cast<float>(sourceType);
		ev.sender = nullptr;

		src->SendEvent(&ev);
	}

	static void DispatchAction(std::string action, int source)
	{
		if (auto* tasks = SKSE::GetTaskInterface(); tasks) {
			tasks->AddTask([a = std::move(action), s = source]() mutable {
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

	// 1 pending per group in DLL (predoctor), replace only if higher priority (lower source number)
	static void EnqueueNormalOrReplaceByGroup(NormalItem&& item)
	{
		std::lock_guard lk(g_mtx);

		for (auto& c : g_cmds) {
			if (c.type != CmdType::kNormal) {
				continue;
			}
			if (c.normal.group == item.group) {
				if (item.source < c.normal.source) {
					spdlog::info("Queue: REPLACE group={} '{}' src={} (was '{}' src={})",
						item.group, item.action, item.source, c.normal.action, c.normal.source);
					c.normal = std::move(item);
					g_cv.notify_one();
				}
				else {
					spdlog::info("Queue: DROP lower-prio group={} '{}' src={}", item.group, item.action, item.source);
				}
				return;
			}
		}

		Command cmd{};
		cmd.type = CmdType::kNormal;
		cmd.normal = std::move(item);
		g_cmds.push_back(std::move(cmd));
		spdlog::info("Queue: PUSH group={} '{}' src={}", g_cmds.back().normal.group, g_cmds.back().normal.action, g_cmds.back().normal.source);
		g_cv.notify_one();
	}

	static void EnqueueCommand(Command&& cmd)
	{
		if (cmd.type == CmdType::kNormal) {
			EnqueueNormalOrReplaceByGroup(std::move(cmd.normal));
			return;
		}

		// ForceBurst: push as a command, does not replace normal-by-group
		{
			std::lock_guard lk(g_mtx);
			g_cmds.push_back(std::move(cmd));
		}
		g_cv.notify_one();
	}

	static void SchedulerThreadProc()
	{
		const auto globalMinGap = std::chrono::milliseconds(250);

		while (g_running.load()) {
			Command next{};
			bool have = false;

			{
				std::unique_lock lk(g_mtx);
				g_cv.wait_for(lk, std::chrono::milliseconds(200), [] {
					return !g_running.load() || !g_cmds.empty();
					});

				if (!g_running.load()) {
					break;
				}
				if (g_cmds.empty()) {
					continue;
				}

				const auto now = Clock::now();

				// 1) FORCE burst: takes precedence, runs as one block
				for (size_t i = 0; i < g_cmds.size(); i++) {
					if (g_cmds[i].type == CmdType::kForceBurst) {
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
						lk.unlock();
						std::this_thread::sleep_until(wakeAt);
						continue;
					}

					next = std::move(g_cmds[bestIdx]);
					g_cmds.erase(g_cmds.begin() + static_cast<std::ptrdiff_t>(bestIdx));
					have = true;

					// Reserve cooldown for chosen normal action
					const auto now2 = Clock::now();
					g_groupReady[next.normal.group] = now2 + std::chrono::milliseconds(static_cast<int>(next.normal.cooldownSec * 1000.0));
					g_globalReady = now2 + globalMinGap;
				}
			}

			if (!have) {
				continue;
			}

			if (next.type == CmdType::kNormal) {
				spdlog::info("Dispatch: group={} '{}' src={} cd={}s",
					next.normal.group, next.normal.action, next.normal.source, next.normal.cooldownSec);
				DispatchAction(std::move(next.normal.action), next.normal.source);
				continue;
			}

			// FORCE burst: ignore normal cooldowns; sequentially dispatch with interval
			spdlog::warn("FORCE burst start: '{}' x{} interval={}s",
				next.burst.action, next.burst.count, next.burst.intervalSec);

			for (int i = 0; i < next.burst.count && g_running.load(); i++) {
				DispatchAction(next.burst.action, 1);
				if (i + 1 < next.burst.count) {
					std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<int>(next.burst.intervalSec * 1000.0)));
				}
			}

			spdlog::warn("FORCE burst done: '{}'", next.burst.action);
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

	spdlog::info("Starting Pipe/Scheduler...");

	g_schedThread = std::thread(SchedulerThreadProc);
	g_pipeThread = std::thread(PipeThreadProc);

	spdlog::info("Pipe/Scheduler started");
}

void TDL_StopPipeServer()
{
	if (!g_running.exchange(false)) {
		return;
	}

	g_cv.notify_all();
	UnblockConnect();

	if (g_pipeThread.joinable()) {
		g_pipeThread.join();
	}
	if (g_schedThread.joinable()) {
		g_schedThread.join();
	}

	{
		std::lock_guard lk(g_mtx);
		g_cmds.clear();
	}

	spdlog::info("Pipe/Scheduler stopped");
}
