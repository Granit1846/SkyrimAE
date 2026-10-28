// src/TDL_Twitch.h
#pragma once

// Starts the native Twitch EventSub client (replaces Streamer.bot + tdl_send.exe).
// Reads Data\SKSE\Plugins\TDL_Twitch.ini; does nothing when [Twitch] Enabled=0. Safe to call multiple times.
void TDL_StartTwitch();
