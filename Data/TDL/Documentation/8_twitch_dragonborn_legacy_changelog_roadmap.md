# Twitch Dragonborn Legacy (TDL)
## Changelog & Roadmap

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Twitch connection & TDL_Twitch.ini: `6_twitch_dragonborn_legacy_twitch_setup.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`   

This document tracks the current state of the mod and the direction of development.  
Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`.

---

TDL evolves gradually and deliberately: the priorities are stability, controllability, and preserving the atmosphere of a trial.

---

## Current version

### Version 1.1.8 — Multilingual out of the box

- The plugin (ESP) is localized: names, effect descriptions and message boxes follow the game language (sLanguage) via Data\Strings, 9 languages
- Radial menu and stats menu follow the game language too
- Fixed typos in menu labels (Blessing, High Hrothgar, Wrath of Heaven, Horror)
- UIExtensions is now listed as a requirement (radial and stats menus)

### Version 1.1.7 — Native Twitch

**Twitch without Streamer.bot**
- The SKSE plugin connects to Twitch itself (EventSub): channel point rewards, bits, chat commands, polls
- One-time login with a code (twitch.tv/activate), token stored encrypted (Windows DPAPI)
- All mappings in `Data\SKSE\Plugins\TDL_Twitch.ini`; comma-separated lists pick a random action (difficulty tiers)
- In-game messages "who did what", fully configurable (`[Messages]`)
- `tdl_send.exe` removed: the mod ships no executables anymore

**Game version**
- Skyrim 1.7.104 support (plugin rebuilt on CommonLibSSE-NG; the plugin is now GPL-3.0, source on GitHub)

**Respawn module built in**
- `TDL_RespawningEncounterZones.esp` / `Tdl_patch1.esp` are no longer needed
- Settings on the MCM Teleport page (game default / custom hours / always fast)
- Fast-respawn window after random dangerous teleports and after fast travel

**Fixes**
- Stage fragments restored: actions triggered from outside could do nothing (broken quest fragment script)
- Actions were lost after loading a save (event registration not kept in saves)
- Repeated low gravity no longer ends slow fall early; no more hanging mid-air without moving
- Gigant: the second active effect is reset correctly
- Inventory "drop all": items are returned on timeout instead of being lost
- Arena could stay locked forever; escort could give duplicate rewards
- MCM Teleport page buttons did nothing
- INI settings are re-applied after loading a save
- Missing MCM strings in all 9 languages (About page, arena time limit, respawn options)

### Version 1.0 — Initial Release

- Base architecture of the stage system (command-based)
- Central event controller
- Full module set:
  - Wrath of God
  - Healing / Blessing
  - Summoning
  - Hunter
  - Show scenarios
  - Chaos events
  - Inventory interventions
  - Teleport scenarios
  - Virus states
  - Weather scenarios
  - Characteristic scenarios
- Full SkyUI MCM integration
- Skyrim SE / AE support
- Multi-language localization
- Support for manual and external control

---

## Update principles

- The mod **does not break existing saves** when updating
- New features are added as separate scenarios/modules
- The stage architecture remains stable
- Experimental ideas are tested in a limited way first

---

## Roadmap (no dates)

Directions considered for future versions:

### New scenarios
- additional variants of pursuit/hunting
- unusual event combinations
- rare “special” interventions

### Expanded interactivity
- deeper integration with external tools
- more control points for streams
- scenarios influenced by audience decisions

### Better feedback
- subtler notifications
- optional expanded debug modes
- improved diagnostics

### Balance and control
- additional intensity controls
- more granular per-scenario tuning
- improved compatibility with other mods

---

## What NOT to expect

- radical architecture rewrites
- turning TDL into a story/quest mod
- simplifying it into a “safe mode”

TDL will evolve, but **its philosophy will remain the same**.

---

## Feedback

Ideas and suggestions are welcome if they:
- do not break the concept
- do not turn the mod into a linear quest
- preserve the element of unpredictability

---

*TDL evolves slowly—because rushing is also a mistake.*

---

# Русская версия
## Changelog и Roadmap

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Подключение Twitch и TDL_Twitch.ini: `6_twitch_dragonborn_legacy_twitch_setup.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

Этот документ — журнал изменений и план развития.  
Описание стадий — в `7_twitch_dragonborn_legacy_description_mods_and_stges.md`.

---

TDL развивается постепенно и осознанно: приоритет — стабильность, управляемость и сохранение атмосферы испытания.

---

## Текущая версия

### Версия 1.1.8 — Мультиязычность «из коробки»

- Плагин (ESP) локализован: имена, описания эффектов и окна сообщений берутся на языке игры (sLanguage) из Data\Strings, 9 языков
- Радиальное меню и меню статистики тоже следуют языку игры
- Исправлены опечатки в пунктах меню (Благословение, Высокий Хротгар, Гнев небес, Хоррор)
- UIExtensions добавлен в требования (радиальное меню и меню статистики)

### Версия 1.1.7 — Twitch напрямую

**Twitch без Streamer.bot**
- SKSE-плагин сам подключается к Twitch (EventSub): награды за баллы, биты, команды чата, голосования
- Одноразовый вход по коду (twitch.tv/activate), токен хранится в зашифрованном виде (Windows DPAPI)
- Все привязки в `Data\SKSE\Plugins\TDL_Twitch.ini`; список через запятую выбирает случайное действие (уровни сложности)
- Сообщения в игре «кто что сделал», полностью настраиваются (`[Messages]`)
- `tdl_send.exe` удалён: в моде больше нет исполняемых файлов

**Версия игры**
- Поддержка Skyrim 1.7.104 (плагин пересобран на CommonLibSSE-NG; плагин теперь под GPL-3.0, исходники на GitHub)

**Модуль респауна встроен**
- `TDL_RespawningEncounterZones.esp` / `Tdl_patch1.esp` больше не нужны
- Настройки на странице MCM «Телепорт» (как в игре / свои часы / всегда быстрый)
- Окно быстрого респауна после случайного опасного телепорта и после быстрого перемещения

**Исправления**
- Восстановлены фрагменты стадий: действия извне могли ничего не делать (сломанный скрипт фрагментов квеста)
- Действия терялись после загрузки сохранения (подписка на события не сохранялась)
- Повторная низкая гравитация больше не обрывает замедленное падение; персонаж не зависает в воздухе
- Гигант: второй активный эффект сбрасывается правильно
- «Потеря всего инвентаря»: при таймауте предметы возвращаются, а не теряются
- Арена могла навсегда заблокироваться; сопровождение могло дать награду дважды
- Кнопки страницы MCM «Телепорт» ничего не делали
- Настройки из INI применяются заново после загрузки сохранения
- Недостающие строки MCM во всех 9 языках (страница «О моде», время арены, настройки респауна)

### Version 1.0 — Initial Release

- Базовая архитектура системы стадий (command-based)
- Центральный контроллер событий
- Полноценная система модулей:
  - Wrath of God
  - Healing / Blessing
  - Summoning
  - Hunter (преследователь)
  - Show-сценарии
  - Chaos-события
  - Inventory-вмешательства
  - Teleport-сценарии
  - Virus-состояния
  - Weather-сценарии
  - Characteristic-сценарии
- Полная интеграция с SkyUI MCM
- Поддержка Skyrim SE / AE
- Многоязычная локализация
- Поддержка ручного и внешнего управления

---

## Принципы обновлений

- Мод **не ломает существующие сейвы** при обновлении
- Новые функции добавляются как отдельные сценарии
- Архитектура стадий сохраняется
- Экспериментальные идеи сначала тестируются ограниченно

---

## Roadmap (без сроков)

Следующие направления рассматриваются для будущих версий:

### 🔹 Новые сценарии
- дополнительные варианты преследования
- нестандартные комбинации событий
- редкие «особые» вмешательства

### 🔹 Расширение интерактива
- более глубокая интеграция с внешними инструментами
- дополнительные точки управления для стримов
- сценарии, зависящие от решений аудитории

### 🔹 Улучшение обратной связи
- более тонкие уведомления
- расширенные debug-режимы (по желанию)
- улучшенная диагностика проблем

### 🔹 Баланс и контроль
- дополнительные настройки интенсивности
- точечная настройка отдельных сценариев
- улучшение совместимости с другими модами

---

## Чего НЕ стоит ожидать
- резких переработок архитектуры
- превращения мода в сюжетный
- упрощения до «безопасного» режима

TDL будет развиваться, но **его философия останется прежней**.

---

## Обратная связь

Идеи и предложения приветствуются, если они:
- не разрушают концепцию
- не превращают мод в линейный квест
- сохраняют элемент непредсказуемости

---

*TDL развивается медленно. Потому что спешка — тоже форма ошибки.*
