// src/TDL_PipeServer.h
#pragma once

// Starts the Named Pipe server (\\.\pipe\TDL_Stream) and the internal scheduler threads.
// Safe to call multiple times.
void TDL_StartPipeServer();

// Stops the pipe server and scheduler threads.
void TDL_StopPipeServer();
