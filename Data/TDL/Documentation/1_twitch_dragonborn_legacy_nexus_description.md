# Twitch Dragonborn Legacy (TDL)

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Streamer.bot setup: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

TDL is a command-driven event system for Skyrim. It introduces modular scenarios that can be triggered on demand:
- controlled chaos effects
- combat/pressure scenarios
- cinematic and disruptive moments
- streamer-friendly interactive control

TDL is **not** a questline. Think of it as a toolbox of staged scenarios.

---

## Key features

- Modular stages (“commands”): each stage is an entry point to a specific module
- In-game configuration via **SkyUI MCM** (recommended)
- **External integration is mandatory** — the mod will not work without the tools folder:  
  `Data\TDL\tools\` (includes `tdl_send.exe`)
- SKSE plugin for runtime logic and integration
- Multiple categories, each configurable independently (e.g., Wrath, Healing/Blessing, Summoning, Hunter, Show, Chaos, Inventory, Teleport, Virus, Weather, Characteristic)

---

## Requirements

See: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
(That file is the single source of truth.)

---

## Safety / tools note

TDL ships with an external helper tool (`tdl_send.exe`) to enable integration.  
The mod does **not** auto-run tools by itself; the tools are used for external interaction.

If your antivirus blocks the tool, add an exclusion for the mod folder.

---

# Русская версия

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Настройка Streamer.bot: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`   

**TDL** — система событий и сценариев для Skyrim, построенная как набор **команд/стадий**. Сценарии можно вызывать по запросу:
- управляемые хаотические эффекты
- боевые и стресс-сценарии
- “кинематографические” вмешательства
- интерактив для стримов и внешнего управления

TDL — **не квест** и не сюжетная линия. Это набор инструментов и сценариев.

---

## Ключевые особенности

- Модульные стадии (“команды”): каждая стадия — точка входа в конкретный модуль
- Настройка в игре через **SkyUI MCM** (рекомендуется)
- **Внешняя интеграция обязательна** — без папки tools мод не работает:  
  `Data\TDL\tools\` (включая `tdl_send.exe`)
- SKSE-плагин для логики рантайма и интеграции
- Несколько категорий, каждая настраивается отдельно (например: Wrath, Healing/Blessing, Summoning, Hunter, Show, Chaos, Inventory, Teleport, Virus, Weather, Characteristic)

---

## Требования

См.: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
(это основной документ по установке и зависимостям)

---

## Примечание по tools и безопасности

TDL поставляется с внешним инструментом (`tdl_send.exe`) для интеграции.  
Мод **не запускает** tools автоматически; tools используются для внешнего взаимодействия.

Если антивирус блокирует файл — добавьте исключение для папки мода.
