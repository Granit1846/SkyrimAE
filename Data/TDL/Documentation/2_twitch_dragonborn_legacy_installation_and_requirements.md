# Twitch Dragonborn Legacy (TDL)
## Installation & Requirements

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Streamer.bot setup: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md` 

This document is the single source of truth for installation and prerequisites.  
If other docs mention requirements, trust this file.

---

## Requirements (mandatory)

- Skyrim Special Edition / Anniversary Edition
- SKSE (matching your game version)
- Address Library for SKSE Plugins
- ConsoleUtilSSE
- Papyrus Extender
- **TDL external tools** (shipped with the mod)  
  Must remain at: `Data\TDL\tools\` (including `tdl_send.exe`).  
  **The mod will not work without this folder.**

## Optional (recommended)

- SkyUI (MCM configuration UI)
- MCM Helper
- TrueHUD - HUD Additions
- Lin's VanillaPlus TrueHUD Preset
- True Directional Movement
- Target Focus

---

## Install (MO2 / Vortex / manual)

### Mod managers (MO2 / Vortex)
1. Install the mod archive.
2. Ensure the mod is enabled.
3. Verify these paths exist inside the mod:
   - `Data\SKSE\Plugins\TDL_StreamPlugin.dll`
   - `Data\SKSE\Plugins\TDL_StreamPlugin.ini` (used only in conjunction with the "TDL Configurator" application, not included in the mod archive)
   - `Data\TDL\tools\tdl_send.exe`
   - `Data\TDL\config\TDL_Cooldowns.ini`

### Manual install
Copy the **Data** folder into your Skyrim folder (merge, do not replace unrelated files).

---

## Antivirus / SmartScreen notes

Because the mod ships an `.exe` tool (`tdl_send.exe`), some antivirus products may flag it as suspicious.
- If the file is blocked or quarantined, add an exclusion for the mod folder (and restore the file).
- Do **not** rename or move `Data\TDL\tools\` — the plugin expects this exact location.

---

## First launch checklist

- Launch Skyrim and load a save.
- (Recommended) Open **MCM** → Twitch Dragonborn Legacy and confirm settings are visible.
- If you use logs, check SKSE logs for plugin load confirmation.

---

## Updates

- Update by replacing the mod in your mod manager.
- If you have a custom INI, back it up before updating.

---

## Uninstall

- Disable the mod in your mod manager (or remove installed files).
- Uninstalling complex mods mid-playthrough is not recommended; keep a backup save.

---

# Русская версия
## Установка и требования

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Настройка Streamer.bot: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`   

Этот документ является главным источником правды по установке и зависимостям.  
Если в других документах требования описаны иначе — ориентируйтесь на этот файл.

---

## Требования (обязательно)

- Skyrim Special Edition / Anniversary Edition
- SKSE (версия должна соответствовать версии игры)
- Address Library for SKSE Plugins
- ConsoleUtilSSE
- Papyrus Extender
- **Внешние инструменты TDL** (идут в составе мода)  
  Должны находиться по пути: `Data\TDL\tools\` (включая `tdl_send.exe`).  
  **Без этой папки мод не работает.**

## Опционально (рекомендуется)

- SkyUI (для настройки через MCM)
- MCM Helper
- TrueHUD - HUD Additions
- Lin's VanillaPlus TrueHUD Preset
- True Directional Movement
- Target Focus

---

## Установка (MO2 / Vortex / вручную)

### Через менеджер модов (MO2 / Vortex)
1. Установите архив мода.
2. Убедитесь, что мод включён.
3. Проверьте наличие путей внутри мода:
   - `Data\SKSE\Plugins\TDL_StreamPlugin.dll`
   - `Data\SKSE\Plugins\TDL_StreamPlugin.ini` (используется только совместно с приложением "TDL Configurator", не входит в архив мода)
   - `Data\TDL\tools\tdl_send.exe`
   - `Data\TDL\config\TDL_Cooldowns.ini`

### Ручная установка
Скопируйте папку **Data** в папку Skyrim (объединить папки; не заменять несвязанные файлы).

---

## Антивирус / SmartScreen

Так как в составе мода есть `.exe` (`tdl_send.exe`), некоторые антивирусы могут реагировать.
- Если файл заблокирован/удалён — восстановите его и добавьте исключение для папки мода.
- **Не переносите и не переименовывайте** `Data\TDL\tools\` — плагин ожидает этот путь.

---

## Проверка после запуска

- Запустите Skyrim и загрузите сохранение.
- (Рекомендуется) Откройте **MCM** → Twitch Dragonborn Legacy и убедитесь, что настройки отображаются.
- При необходимости проверьте логи SKSE на предмет успешной загрузки плагина.

---

## Обновление

- Обновляйте через менеджер, заменяя мод целиком.
- Если вы вручную правили INI — сделайте бэкап перед обновлением.

---

## Удаление

- Отключите мод в менеджере (или удалите файлы).
- Удаление сложных модов в середине прохождения не рекомендуется; держите резервное сохранение.
