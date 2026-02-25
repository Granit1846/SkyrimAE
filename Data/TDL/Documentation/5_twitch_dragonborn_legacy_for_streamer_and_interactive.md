# Twitch Dragonborn Legacy (TDL)
## For streamers & interactive control

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Streamer.bot setup: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md` 

This document is about streaming scenarios and external control.  
For installation and requirements, use: `2_twitch_dragonborn_legacy_installation_and_requirements.md`.

---

## Why TDL works well on streams

TDL was designed so that events can be triggered **deliberately and controllably**, not only by random chance.

- each event is a separate command/stage
- no mandatory sequence
- you can change intensity and disable categories
- well suited for challenge runs and interactive control
- can be controlled manually or via a chat-bot (the bot must be able to run an external application by trigger, e.g., Streamer.bot)

---

## External control (mandatory)

TDL relies on external integration via tools that must remain here:

- `Data\TDL\tools\` (including `tdl_send.exe`)

Without this folder the mod **will not work**.

---

## Typical interaction patterns

- viewers trigger a specific scenario (via Bits/Channel Points/Polls/Donations — depending on your setup)
- moderators switch “modes” (e.g., softer/harder presets)
- automation by time/donation/keyword (through your streaming tooling)

---

## Trigger examples (Streamer.bot)

If you want automatic triggers, you can bind events to Actions, for example:
- Channel Points → Twitch → Channel Reward → Redeemed (SOURCE=2)
- Bits → Twitch → Cheer (SOURCE=1)
- Votes → Twitch → Polls → Poll Ended/Completed (SOURCE=3)

For donations, manual execution via a command trigger (or a “force” trigger) is recommended unless your donation integration is fully under control.

---

## If the bot is not configured (manual fallback)

If your chat-bot is not configured, you can still trigger commands manually by running:

`<Game>\Data\TDL\tools\tdl_send.exe`  
Example:
`<Game>\Data\TDL\tools\tdl_send.exe normal system_ping 2`

All available commands can be found in `README.txt` (TDL folder).

---

## Creating new commands / actions / queues (Streamer.bot)

- To create new triggers, open **Commands** and add a trigger based on your needs (or copy an existing one).
- To create new commands, open **Actions** (you can duplicate an existing action and modify it).
- Important: for proper queue behavior, open **Queues**, create a new queue, and then assign that queue to the relevant Actions.

When creating new commands, note that they should start with `normal` or `force` (see `README.txt` in the TDL folder).

---

## Stream UX recommendations

- start with low intensity
- enable categories gradually
- do not overload queues: keep each group queue under ~15 concurrent launches
- you can manually adjust cooldowns if needed (they exist to prevent broken logic from repeated spawns):
  - `<Game>\Data\TDL\config\TDL_Cooldowns.ini`

---

# Русская версия
## Для стримеров и интерактивных сценариев

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Настройка Streamer.bot: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

Этот документ — про стрим-сценарии и внешнее управление.  
Инструкции по установке и требованиям — в `2_twitch_dragonborn_legacy_installation_and_requirements.md`.

---

## Почему TDL подходит для стримов

TDL проектировался так, чтобы события можно было запускать **осознанно и управляемо**, а не только “рандомом”.

- каждое событие — отдельная команда/стадия
- нет обязательной последовательности
- можно менять интенсивность и отключать категории
- удобно для челлендж-ранов и интерактива
- управляется вручную или с помощью чат-бота (чат-бот должен уметь запускать стороннее приложение по триггеру, например Streamer.bot)

---

## Внешнее управление (обязательно)

TDL использует внешнюю интеграцию через инструменты, которые должны находиться здесь:

- `Data\TDL\tools\` (включая `tdl_send.exe`)

Без этой папки мод **не работает**.

---

## Типовые сценарии интерактива

- зритель выбирает сценарий (покупка за Bits, покупка за баллы канала, голосование или донаты)
- запускается стадия:
  - если чат-бот настроен правильно, он сам реагирует на триггер и запускает команду
  - если чат-бот настроен не полностью, стример или модератор запускает триггер вручную (например: `!test`)
  - если чат-бот не настроен, запуск возможен только вручную: **Win+R** →
    `"<Game>\Data\TDL\tools\tdl_send.exe" normal system_ping 2`
- все команды для запуска можно найти в файле `README.txt` (папка TDL)

---

## Рекомендации по UX стрима

- начните с низкой интенсивности
- включайте категории постепенно (очередь на каждую группу — не больше 15 запусков одновременно)
- при необходимости вы можете вручную изменить интервалы запуска стадий (ограничения выставлены специально, чтобы не сломать логику игры при многократном спавне):
  - файл находится по пути: `<Game>\Data\TDL\config\TDL_Cooldowns.ini`
