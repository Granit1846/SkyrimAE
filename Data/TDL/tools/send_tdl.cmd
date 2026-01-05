@echo off
setlocal

REM Usage: send_tdl.cmd ACTION [SOURCE]
set "ACTION=%~1"
set "SOURCE=%~2"

if "%ACTION%"=="" (
  echo Usage: %~nx0 ACTION [SOURCE]
  exit /b 1
)

if "%SOURCE%"=="" set "SOURCE=2"

powershell -NoProfile -ExecutionPolicy Bypass ^
  -File "%~dp0send_tdl.ps1" ^
  -Action "%ACTION%" ^
  -Source %SOURCE%

endlocal
