// src/TDL_PipeServer.h
#pragma once

// Starts the Named Pipe server (\\.\pipe\TDL_Stream) and the internal scheduler threads.
// Safe to call multiple times.
void TDL_StartPipeServer();

// Stops the pipe server and scheduler threads.
void TDL_StopPipeServer();

// Re-applies TDL_StreamPlugin.ini to TESGlobals (savegames store globals and would override the INI).
void TDL_ReloadGameplayConfig();

#include <filesystem>
#include <string>
#include <unordered_map>

// Parses a pipe-protocol line ("ACTION|SOURCE", "FORCE|ACTION|COUNT", ...) and queues it.
// notice: optional in-game notification shown when the action actually fires (e.g. "viewer: reward").
void TDL_SubmitLine(const std::string& line, const std::string& notice = {});

// section -> key -> value; section/key are trimmed and ASCII-lowercased.
using TDL_IniData = std::unordered_map<std::string, std::unordered_map<std::string, std::string>>;
TDL_IniData TDL_LoadIni(const std::filesystem::path& iniPath);
