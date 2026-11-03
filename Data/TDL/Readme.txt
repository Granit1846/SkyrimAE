TDL - Twitch Dragonborn Legacy 1.3.1-beta
=========================================

Your Twitch viewers control Skyrim: channel point rewards, bits, chat commands
and polls trigger dragons, hunters, curses, teleports, weather and more.
Since 1.1 the mod connects to Twitch by itself - no Streamer.bot, no extra programs.

Full documentation: Data\TDL\Documentation (English + Russian).
Support the author: https://boosty.to/skeorz
New in 1.3 (beta): settings page in the browser (MCM -> About), Arena 2.0 - own hall, gong, reward chest
New in 1.2: OBS overlay, chat replies, pause, anti-spam, viewer stats, raid/sub/hype train events,
chat voting, sound cue - see Documentation\9_twitch_dragonborn_legacy_stream_features.md


Requirements
------------
- Skyrim Special Edition / Anniversary Edition (tested on 1.7.104)
- SKSE64 for your game version
- Address Library for SKSE Plugins
- powerofthree's Papyrus Extender
- ConsoleUtilSSE NG (a version that supports your game version)
- SkyUI + MCM Helper (in-game settings menu)
- UIExtensions (radial menu and stats menu)
Multilingual out of the box: the mod follows your game language (9 languages), no translation files needed.
Optional: True Directional Movement, TrueHUD, Target Focus (used by some stages).


Quick start
-----------
1) Install the archive with your mod manager (Vortex / MO2) and enable it.
   Do not use TDL_RespawningEncounterZones.esp or Tdl_patch1.esp from older
   versions - the respawn module is built in now (MCM -> Teleport page).
2) Start the game through SKSE.
3) First launch only: the game shows a code and opens twitch.tv/activate in your
   browser. Log in with the account you STREAM from and enter the code.
   The login is stored encrypted for your Windows user in
   Documents\My Games\Skyrim Special Edition\SKSE\TDL_Twitch.token
   (delete this file to log out).
4) Load a save and type in your Twitch chat:  !tdl_heal
   You get healed and see "<your name> исцелил вас" in the top-left corner.


What viewers can use
--------------------
Everything is set in  Data\SKSE\Plugins\TDL_Twitch.ini  (UTF-8, changes apply
while the game is running):

[Rewards]   channel points reward title = action(s)    (Affiliate/Partner only)
[Bits]      minimum amount = action(s)                  (largest threshold wins)
[Chat]      !command = action(s)                        (broadcaster/mods by default)
[Poll]      winning choice title = action(s)
[Messages]  action = in-game text, {user} = viewer name, {trigger} = what was used

A value can be:
  ACTION                one action, e.g. SUMMON_DRAGON
  A, B, C               a random one from the list (difficulty tiers)
  FORCE|ACTION|COUNT    a burst (see below)

The default file has four difficulty tiers (light / medium / heavy / epic) for
rewards and bits, a few chat commands and Russian in-game messages - translate
[Messages] into your language if you like. Create the rewards in your Twitch
dashboard with exactly the titles from [Rewards] (or rename them in the INI).

[Twitch] options:
  Enabled=1             0 = no Twitch connection
  ChatAllowEveryone=0   1 = chat commands from everyone, not only broadcaster/mods
  Notify=1              in-game "who did what" messages
  PollName=Чат          name used in messages for poll results


Actions
-------
System:     SYSTEM_PING  SYSTEM_HEALING  SYSTEM_BLESSING
Wrath:      WRATH_11  WRATH_12  WRATH_13
Summoning:  SUMMON_ANY  SUMMON_SKELETON  SUMMON_ANIMAL  SUMMON_HUMANOID
            SUMMON_UNDEAD  SUMMON_STRONG  SUMMON_DRAGON
Hunter:     HUNTER_START
Show:       COMEDY_FAKE_HERO  COMEDY_HORROR  COMEDY_ARENA  COMEDY_ESCORT
Chaos:      CHAOS_LOW_G  CHAOS_BACKFIRE
Inventory:  INVENTORY_SCATTER  INVENTORY_DROP_ALL
Teleport:   TELEPORT_RANDOM_CITY  TELEPORT_RANDOM_DANGER  TELEPORT_HIGH_HROTHGAR
            TELEPORT_WHITERUN  TELEPORT_SOLITUDE  TELEPORT_WINDHELM  TELEPORT_RIFTEN
            TELEPORT_MARKARTH  TELEPORT_FALKREATH  TELEPORT_DAWNSTAR
Virus:      VIRUS_DISEASE  VIRUS_WEREWOLF  VIRUS_VAMPIRE
Weather:    WEATHER_CLEAR  WEATHER_RAIN  WEATHER_SNOW  WEATHER_STORM  WEATHER_FOG  WEATHER_RESET
Gigant:     GIGANT_BIG  GIGANT_SMALL  GIGANT_SPEED  GIGANT_SLOW  GIGANT_RESET

Werewolf, vampire lord and "drop all items" are hard to undo - think twice before
giving them to chat.


Queue and cooldowns
-------------------
Every action belongs to a group (summon, weather, teleport...). A group fires one
action at a time and then waits for its cooldown; the rest wait in the queue
(up to 15 per group, 8 for virus/show/inventory). Priority: bits > channel points
and chat > polls. Cooldowns: Data\TDL\config\TDL_Cooldowns.ini (read at game start).


FORCE (bursts, for the streamer)
--------------------------------
FORCE|ACTION|COUNT[|INTERVAL] fires a series and ignores cooldowns. Allowed:
SUMMON_* (up to 50), INVENTORY_SCATTER (10), TELEPORT_RANDOM_CITY (5),
TELEPORT_RANDOM_DANGER (5), VIRUS_DISEASE (15). Interval 0.75-5 s (teleports 7-10 s).
FORCE1|ACTION fires one action immediately: SYSTEM_HEALING, WRATH_11/12/13.
Heavy bursts can freeze or crash the game - use them deliberately.


Local control without Twitch (advanced)
---------------------------------------
The plugin also listens on the named pipe \\.\pipe\TDL_Stream for lines like
  SYSTEM_PING|2     FORCE|SUMMON_SKELETON|3     FORCE1|SYSTEM_HEALING
Helper scripts send_raw.cmd / send_raw.ps1 (PowerShell) are in the GitHub repository
(Data/TDL/tools); they are not needed to play.
SOURCE: 1 = bits, 2 = points/chat, 3 = poll.


Logs and troubleshooting
------------------------
Documents\My Games\Skyrim Special Edition\SKSE\TDL_StreamPlugin.log shows the
Twitch login, received events ("Twitch: !tdl_heal by ... -> SYSTEM_HEALING|2")
and the queue ("Dispatch: ...").

- No login window / "integration stopped": restart the game to get a new code.
- A chat command does nothing: by default only the broadcaster and moderators may
  use chat commands (ChatAllowEveryone=1 changes that). Check the log.
- "failed to open address library file": Address Library does not match your game version.


License and source
------------------
The SKSE plugin is free software under GPL-3.0-or-later (it uses CommonLibSSE-NG).
Source code: https://github.com/Granit1846/SkyrimAE
See LICENSE.txt in this folder.
