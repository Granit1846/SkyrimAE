TDL — Twitch Dragonborn Legacy control via Named Pipe
===========================================================

Purpose
-------
The mod receives external commands (bot / streaming software / scripts) and triggers effects in the game.

Transport: Windows Named Pipe
  \\.\pipe\TDL_Stream

The recommended way to send commands is the tdl_send.exe utility (no console and no PowerShell).
It accepts arguments WITHOUT the "|" character and internally builds the string for the named pipe.


File structure (current)
------------------------
IMPORTANT: The SKSE plugin must always be located here (do not move it):
  Data\SKSE\Plugins\TDL_StreamPlugin.dll

All derived mod files are located in:
  Data\TDL\

Utilities:
  Data\TDL\Tools\tdl_send.exe      — sends commands to the pipe (no console)

Config:
  Data\TDL\Config\TDL_Cooldowns.ini — cooldowns / group defaults / FORCE limits (global for the mod)


Requirements
------------
1) The game is running and a save is loaded (the world is fully loaded).
2) The TDL mod and the SKSE plugin (TDL_StreamPlugin.dll) are installed.
3) Windows 10/11 (Named Pipe support).


Quick start (manual test)
-------------------------
1) Launch the game and load a save.
2) Press Win+R and run:

Ping (recommended first):
  "PATH_TO_GAME\Data\TDL\Tools\tdl_send.exe" NORMAL SYSTEM_PING 2
  ("PATH_TO_GAME\Data\TDL\Tools\send_raw.cmd" NORMAL SYSTEM_PING 2)

Example for the default Steam installation (replace the path with yours):
  "F:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data\TDL\Tools\tdl_send.exe" NORMAL SYSTEM_PING 2

If PING works, the communication chain is configured correctly.


How to connect to Streamer.bot / SAMMI / any software
-----------------------------------------------------
Any action of type "Run program" / "Execute" / "Launch" is sufficient.

Program (path to executable):
  <Skyrim>\Data\TDL\Tools\tdl_send.exe

Arguments:
  NORMAL SYSTEM_PING 2
  NORMAL SUMMON_SKELETON 2
  FORCE1 SYSTEM_HEALING
  FORCE SUMMON_DRAGON 10 1.0

Notes:
- The "|" character is NOT used in arguments.
- tdl_send.exe builds the pipe string internally and sends it to the named pipe.


Where to find logs
------------------
1) DLL / SKSE log (plugin loading, pipe startup, received messages):
   Documents\My Games\Skyrim Special Edition\SKSE\TDL_StreamPlugin.log

2) Papyrus logs (accepted / rejected actions and reasons):
   - main Papyrus log:
     Documents\My Games\Skyrim Special Edition\Logs\Script\Papyrus.0.log
   - if a separate TDL log file is enabled in the mod:
     Documents\My Games\Skyrim Special Edition\Logs\Script\User\TDL.0.log


Normal commands (main mode)
---------------------------
Logical protocol format (actual pipe message):
  ACTION|SOURCE

Where:
  ACTION — action identifier (see list below)
  SOURCE (source priority):
    1 = beats   (higher priority)
    2 = points
    3 = vote    (lower priority)

Actual execution via tdl_send.exe (WITHOUT "|"):
  tdl_send.exe NORMAL ACTION [SOURCE]

If SOURCE is not specified, using 2 (points) is recommended.


Examples:
  tdl_send.exe NORMAL SYSTEM_PING 2
  tdl_send.exe NORMAL WEATHER_RAIN 1
  tdl_send.exe NORMAL TELEPORT_RANDOM_CITY 3


ACTION list (normal commands)
-----------------------------
1) Connection check
  SYSTEM_PING

2) Heal / blessing
  SYSTEM_HEALING
  SYSTEM_BLESSING

3) Summoning
  SUMMON_ANY
  SUMMON_SKELETON
  SUMMON_ANIMAL
  SUMMON_HUMANOID
  SUMMON_UNDEAD
  SUMMON_STRONG
  SUMMON_DRAGON

4) Hunter
  HUNTER_START

5) Show
  COMEDY_FAKE_HERO
  COMEDY_HORROR
  COMEDY_ARENA
  COMEDY_ESCORT

6) Chaos
  CHAOS_LOW_G
  CHAOS_BACKFIRE

7) Inventory
  INVENTORY_SCATTER
  INVENTORY_DROP_ALL

8) Teleport
  TELEPORT_RANDOM_CITY
  TELEPORT_RANDOM_DANGER
  TELEPORT_HIGH_HROTHGAR
  TELEPORT_WHITERUN
  TELEPORT_SOLITUDE
  TELEPORT_WINDHELM
  TELEPORT_RIFTEN
  TELEPORT_MARKARTH
  TELEPORT_FALKREATH
  TELEPORT_DAWNSTAR

9) Virus
  VIRUS_DISEASE
  VIRUS_WEREWOLF
  VIRUS_VAMPIRE

10) Weather
  WEATHER_CLEAR
  WEATHER_RAIN
  WEATHER_SNOW
  WEATHER_STORM
  WEATHER_FOG
  WEATHER_RESET

11) Gigantism / speed
  GIGANT_BIG
  GIGANT_SMALL
  GIGANT_SPEED
  GIGANT_SLOW
  GIGANT_RESET


FORCE commands (manual mode)
----------------------------
FORCE commands are NOT intended for chat.
They are triggered manually by the streamer / moderators (or an admin interface of your software).

There are two types of FORCE:

1) FORCE1 (single forced action)
   Logical format (pipe):
     FORCE1|ACTION

   Execution via tdl_send.exe:
     tdl_send.exe FORCE1 ACTION

   Allowed ACTION:
     SYSTEM_HEALING
     WRATH_11
     WRATH_12
     WRATH_13

   Examples:
     tdl_send.exe FORCE1 SYSTEM_HEALING
     tdl_send.exe FORCE1 WRATH_12


2) FORCE (BURST series)
   Logical format (pipe):
     FORCE|ACTION|COUNT
   or:
     FORCE|ACTION|COUNT|INTERVAL

   Execution via tdl_send.exe:
     tdl_send.exe FORCE ACTION COUNT [INTERVAL]

   If INTERVAL is not specified, the default value from the configuration is used (see INI).

   Restrictions (typo protection):
   - COUNT maximum is 50 (hard limit)
   - INTERVAL default clamp: 0.75 .. 5.0 seconds
   - TELEPORT_RANDOM_CITY / TELEPORT_RANDOM_DANGER: forced interval 7..10 seconds
     (otherwise a teleport chain faster than location loading is possible)

   Allowed ACTION for series and additional limits:
     - SUMMON_*                 : up to 50
     - INVENTORY_SCATTER        : up to 10
     - TELEPORT_RANDOM_CITY     : up to 5
     - TELEPORT_RANDOM_DANGER   : up to 5
     - VIRUS_DISEASE            : up to 15

   Examples:
     tdl_send.exe FORCE SUMMON_DRAGON 10
     tdl_send.exe FORCE SUMMON_DRAGON 10 1.0
     tdl_send.exe FORCE INVENTORY_SCATTER 10
     tdl_send.exe FORCE TELEPORT_RANDOM_CITY 5
     tdl_send.exe FORCE VIRUS_DISEASE 15 0.9


Important warning (FORCE / BURST)
---------------------------------
FORCE / BURST actions are triggered manually and deliberately bypass normal queues and cooldowns.
With a large number of heavy effects (for example, mass summoning / object spawning /
frequent teleports), the Skyrim engine may not withstand the load:
severe FPS drops, freezes, and crashes are possible.

By using FORCE / BURST, you accept this risk.

STOP_ALL (bot pause) does NOT interrupt an already running FORCE / BURST —
it only stops further event collection and sending by the bot.


Cooldowns: global configuration via INI
---------------------------------------
All cooldowns are located in:
  Data\TDL\Config\TDL_Cooldowns.ini

Principle:
- The DLL reads the INI at startup (usually a game restart is required after changing the INI).
- The bot may read the same INI and try to plan its queue, but stability does not depend on the bot:
  final limiting and scheduling are performed by the DLL.
- If an explicit cooldown is specified for an ACTION, it is used.
- If no cooldown is specified for an ACTION, the default cooldown of the group is used (GroupDefaults).


Permissions and control (recommended for bots)
----------------------------------------------
Streamer:
- may use all FORCE / ADMIN actions
- may have an exclusive STOP_ALL command (pause the bot scheduler)

Moderators:
- may use FORCE / ADMIN actions (at the streamer’s discretion / bot settings)
- may not have access to STOP_ALL (if configured that way)

Chat:
- must not have access to FORCE / ADMIN
- affects the game only via points / beats / vote (if enabled)


Voting (as simple as possible, if you use a bot)
------------------------------------------------
The streamer starts a vote with 2–5 options.
Chat votes:
  !1 ... !5   (or simply 1 ... 5)

Rules:
- 1 person = 1 vote
- votes for options are summed
- the winner is the option with the highest number of votes
- in case of a tie, the option that received the LAST vote wins
- after voting ends, the bot sends a single command of the winning option to the DLL (SOURCE=3)


How to test right now (minimum)
-------------------------------
1) Launch the game and load a save.
2) Check ping:
   tdl_send.exe NORMAL SYSTEM_PING 2
3) Check a normal command:
   tdl_send.exe NORMAL SUMMON_SKELETON 2
4) Check FORCE1:
   tdl_send.exe FORCE1 SYSTEM_HEALING


Common issues
-------------
1) Command is not sent / connection error:
   - the game is not running or the save is not fully loaded
   - the SKSE plugin did not load (check TDL_StreamPlugin.log)

2) Command is sent, but the action does not trigger:
   - the action was rejected due to priority or cooldown (check Papyrus logs and/or TDL.0.log)
   - the action is disabled in the mod settings / action table


Tip
---
For diagnostics, always use:
  tdl_send.exe NORMAL SYSTEM_PING 2

If PING works, the communication chain is configured correctly.
