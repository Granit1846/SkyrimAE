// src/TDL_PipeServer.h
#pragma once

// Starts the Named Pipe server (\\.\pipe\TDL_Stream) and the internal scheduler threads.
// Safe to call multiple times.
void TDL_StartPipeServer();

// Stops the pipe server and scheduler threads.
void TDL_StopPipeServer();
void TDL_WakeScheduler();
// Applies Twitch pause changes at the scheduler's queue/dispatch gate.
void TDL_SetTwitchPauseState(bool paused, bool hold);

// Re-applies TDL_StreamPlugin.ini to TESGlobals (savegames store globals and would override the INI).
void TDL_ReloadGameplayConfig();

#include <filesystem>
#include <string>
#include <unordered_map>

// Where a queued action came from; travels with it through the queue.
struct TDL_Origin
{
	std::string notice;        // UTF-8 text shown in game and on the overlay when it fires ("" = silent)
	std::string who;           // viewer name
	std::string trigger;       // reward title, "500 bits", "!cmd"
	std::string rewardId;      // channel points redemption (empty otherwise)
	std::string redemptionId;
	std::string queueUser;     // Twitch user ID reserved by the anti-spam queue limit
	bool twitch = false;
	std::string userId;        // stable viewer ID for stats (bits may be queue-limit exempt)
};

struct TDL_SubmitInfo
{
	bool accepted = false;  // false: bad line or the group queue is full
	int position = 0;       // place among queued actions of the same group (1 = next)
	int etaSec = 0;         // rough time until it fires
};

// Parses a pipe-protocol line ("ACTION|SOURCE", "FORCE|ACTION|COUNT", ...) and queues it.
TDL_SubmitInfo TDL_SubmitLine(const std::string& line, const TDL_Origin& origin = {});

// Called after an action or full burst completes (true), or is canceled/evicted (false).
// Must not call back into the queue.
using TDL_OutcomeHook = void (*)(const TDL_Origin& origin, bool fired);
void TDL_SetOutcomeHook(TDL_OutcomeHook hook);

// Queue and recent actions for the stream overlay, as UTF-8 JSON.
std::string TDL_GetStateJson();
void TDL_Notify(const std::string& text);

// section -> key -> value; section/key are trimmed and ASCII-lowercased.
using TDL_IniData = std::unordered_map<std::string, std::unordered_map<std::string, std::string>>;
TDL_IniData TDL_LoadIni(const std::filesystem::path& iniPath);
