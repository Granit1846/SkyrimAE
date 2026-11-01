# Twitch Dragonborn Legacy (TDL)
## Installation & Requirements

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Twitch connection & TDL_Twitch.ini: `6_twitch_dragonborn_legacy_twitch_setup.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

This document is the single source of truth for installation and prerequisites.

---

## Requirements (mandatory)

- Skyrim Special Edition / Anniversary Edition (tested on **1.7.104**)
- SKSE64 matching your game version
- Address Library for SKSE Plugins (the file for your game version)
- powerofthree's Papyrus Extender
- ConsoleUtilSSE NG (a build that supports your game version; used by the teleport respawn window)
- SkyUI and MCM Helper (settings menu)

## Optional

- True Directional Movement, TrueHUD (+ Lin's VanillaPlus TrueHUD Preset), Target Focus - used by some stages

---

## Install

1. Install the archive with Vortex or MO2 and enable it (manual: copy the contents into `Skyrim Special Edition\Data\`).
2. **Updating from 1.0.x:** delete the old `Data\TDL\tools` folder (with `tdl_send.exe`) if it is still there, remove the TDL actions from
   Streamer.bot and disable `TDL_RespawningEncounterZones.esp` / `Tdl_patch1.esp` (the respawn module is built in now).
3. Check these files exist:
   - `Data\SKSE\Plugins\TDL_StreamPlugin.dll`
   - `Data\SKSE\Plugins\TDL_Twitch.ini`
   - `Data\TDL\config\TDL_Cooldowns.ini`
4. Start the game through SKSE. On the first start a code is shown and twitch.tv/activate opens -
   log in with the account you stream from (see `6_twitch_dragonborn_legacy_twitch_setup.md`).

---

## First launch checklist

- Load a save, open MCM -> Twitch Dragonborn Legacy.
- Type `!tdl_heal` in your Twitch chat: you are healed and a message appears in the top-left corner.
- Log: `Documents\My Games\Skyrim Special Edition\SKSE\TDL_StreamPlugin.log` (look for "4 of 4 subscriptions active").

---

## Updates / uninstall

- Back up `TDL_Twitch.ini` if you edited it, then replace the mod in your mod manager. Saves stay compatible.
- Uninstalling scenario mods mid-playthrough is not recommended; keep a backup save.

---

# Русская версия
## Установка и требования

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Подключение Twitch и TDL_Twitch.ini: `6_twitch_dragonborn_legacy_twitch_setup.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

Этот документ - основной источник по установке и зависимостям.

---

## Требования (обязательно)

- Skyrim Special Edition / Anniversary Edition (проверено на **1.7.104**)
- SKSE64 под вашу версию игры
- Address Library for SKSE Plugins (файл под вашу версию игры)
- powerofthree's Papyrus Extender
- ConsoleUtilSSE NG (сборка с поддержкой вашей версии игры; нужна окну респауна телепорта)
- SkyUI и MCM Helper (меню настроек)

## Необязательно

- True Directional Movement, TrueHUD (+ Lin's VanillaPlus TrueHUD Preset), Target Focus - используются некоторыми стадиями

---

## Установка

1. Установите архив через Vortex или MO2 и включите его (вручную: скопируйте содержимое в `Skyrim Special Edition\Data\`).
2. **Обновление с 1.0.x:** удалите старую папку `Data\TDL\tools` (с `tdl_send.exe`), если она осталась, уберите действия TDL из
   Streamer.bot и выключите `TDL_RespawningEncounterZones.esp` / `Tdl_patch1.esp` (модуль респауна теперь встроен).
3. Проверьте, что есть файлы:
   - `Data\SKSE\Plugins\TDL_StreamPlugin.dll`
   - `Data\SKSE\Plugins\TDL_Twitch.ini`
   - `Data\TDL\config\TDL_Cooldowns.ini`
4. Запустите игру через SKSE. При первом запуске появится код и откроется twitch.tv/activate -
   войдите в аккаунт, с которого стримите (см. `6_twitch_dragonborn_legacy_twitch_setup.md`).

---

## Проверка после первого запуска

- Загрузите сохранение, откройте MCM -> Twitch Dragonborn Legacy.
- Напишите в чат Twitch `!tdl_heal`: вас вылечит, в левом верхнем углу появится сообщение.
- Журнал: `Документы\My Games\Skyrim Special Edition\SKSE\TDL_StreamPlugin.log` (строка «4 of 4 subscriptions active»).

---

## Обновление / удаление

- Сохраните копию `TDL_Twitch.ini`, если меняли его, затем замените мод в менеджере. Сохранения совместимы.
- Удалять сценарные моды посреди прохождения не рекомендуется; держите резервное сохранение.
