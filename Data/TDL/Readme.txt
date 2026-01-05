TDL Stream Tools (TwitchDragonbornLegacy)
README – External Sender (Named Pipe)

What this is
------------
This mod includes a small “sender” utility that can trigger in-game actions by writing commands to a Windows Named Pipe.
It is intended for Streamer.bot / SAMMI / Lioranboard / OBS / any software that can run a program.

Files in this folder
--------------------
send_tdl.cmd   - universal launcher (recommended). Call this from any software.
send_tdl.ps1   - PowerShell sender (used by send_tdl.cmd).

Install / Location
------------------
After installing the mod, these files are located at:
<Skyrim>\Data\TDL_Tools\

Recommended way to run
----------------------
Use send_tdl.cmd. It handles the PowerShell call and works regardless of “Start in” folder.

Command format
--------------
send_tdl.cmd ACTION [SOURCE]

ACTION  - an action ID (examples below)
SOURCE  - optional priority source:
          1 = beats (highest priority)
          2 = points (default)
          3 = vote  (lowest priority)

If SOURCE is omitted, it defaults to 2.

Examples (Windows Run / Streamer software)
------------------------------------------
1) Ping (safe test):
send_tdl.cmd SYSTEM_PING 2

2) Summon dragon:
send_tdl.cmd SUMMON_DRAGON 2

3) Heal:
send_tdl.cmd SYSTEM_HEALING 2

4) Weather:
send_tdl.cmd WEATHER_RAIN 2
send_tdl.cmd WEATHER_CLEAR 2
send_tdl.cmd WEATHER_FOG 2
send_tdl.cmd WEATHER_RESET 2

5) Chaos:
send_tdl.cmd CHAOS_LOW_G 2
send_tdl.cmd CHAOS_BACKFIRE 2

6) Gigant:
send_tdl.cmd GIGANT_BIG 2
send_tdl.cmd GIGANT_SMALL 2
send_tdl.cmd GIGANT_SPEED 2
send_tdl.cmd GIGANT_SLOW 2
send_tdl.cmd GIGANT_RESET 2

Notes / Troubleshooting
-----------------------
1) Game must be running and a save must be loaded.
   The Named Pipe server starts after the game finishes loading data.

2) If a command “does nothing”:
   - the action may be on cooldown
   - the action may be disabled
   - a higher-priority action may be active

3) Where to check logs:
   - DLL / pipe log:
     Documents\My Games\Skyrim Special Edition\SKSE\TDL_StreamPlugin.log

   - Papyrus script log (if enabled by the mod):
     Documents\My Games\Skyrim Special Edition\Logs\Script\User\TDL.0.log

4) PowerShell policy:
   send_tdl.cmd runs PowerShell with ExecutionPolicy Bypass for this script.
   If your security software blocks scripts, whitelist this folder or use the .cmd call from your streamer software.

Integration tips
----------------
Any software that can “Run a Program” can trigger actions:
- Program: <Skyrim>\Data\TDL_Tools\send_tdl.cmd
- Arguments: e.g. SYSTEM_PING 2
