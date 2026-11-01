// src/TDL_Twitch.h
#pragma once
#include <string>

// Starts the native Twitch EventSub client (replaces Streamer.bot + tdl_send.exe).
// Reads Data\SKSE\Plugins\TDL_Twitch.ini; does nothing when [Twitch] Enabled=0. Safe to call multiple times.
void TDL_StartTwitch();
void TDL_StopTwitch();
bool TDL_IsTwitchPaused();  // reloads the INI if it changed
bool TDL_IsTwitchPauseHold();  // reloads the INI if it changed
std::string TDL_GetTwitchStateJson();
