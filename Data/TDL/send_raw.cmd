@echo off
setlocal

REM Usage:
REM   send_raw.cmd NORMAL ACTION SOURCE
REM   send_raw.cmd FORCE1 ACTION
REM   send_raw.cmd FORCE ACTION COUNT [INTERVAL]

set "MODE=%~1"
if "%MODE%"=="" goto :help

if /I "%MODE%"=="NORMAL" (
  set "ACTION=%~2"
  set "SOURCE=%~3"
  if "%ACTION%"=="" goto :help
  if "%SOURCE%"=="" set "SOURCE=2"
  set "LINE=%ACTION%|%SOURCE%"
  goto :send
)

if /I "%MODE%"=="FORCE1" (
  set "ACTION=%~2"
  if "%ACTION%"=="" goto :help
  set "LINE=FORCE1|%ACTION%"
  goto :send
)

if /I "%MODE%"=="FORCE" (
  set "ACTION=%~2"
  set "COUNT=%~3"
  set "INTERVAL=%~4"
  if "%ACTION%"=="" goto :help
  if "%COUNT%"=="" goto :help

  if "%INTERVAL%"=="" (
    set "LINE=FORCE|%ACTION%|%COUNT%"
  ) else (
    set "LINE=FORCE|%ACTION%|%COUNT%|%INTERVAL%"
  )
  goto :send
)

:help
echo.
echo Usage:
echo   %~nx0 NORMAL ACTION SOURCE
echo   %~nx0 FORCE1 ACTION
echo   %~nx0 FORCE ACTION COUNT [INTERVAL]
echo.
echo Examples:
echo   %~nx0 NORMAL SYSTEM_PING 2
echo   %~nx0 FORCE1 SYSTEM_HEALING
echo   %~nx0 FORCE SUMMON_DRAGON 10 1.0
echo.
exit /b 1

:send
powershell -NoProfile -ExecutionPolicy Bypass ^
  -File "%~dp0send_raw.ps1" ^
  -Line "%LINE%"

endlocal
