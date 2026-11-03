// src/TDL_Overlay.h
#pragma once

// Starts the local overlay and settings server on [Overlay] Port, even when the overlay display is disabled.
void TDL_StartOverlay();
int TDL_OverlayPort();
bool TDL_OpenSettings();
