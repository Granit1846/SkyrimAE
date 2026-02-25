# English version
## Streamer.bot setup

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Streamer.bot setup: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md` 

This document is a helper for configuring the local chat-bot **Streamer.bot**.

---

## Streamer.bot configuration

- First, download Streamer.bot from the official website.
- Sign in / authorize inside the application.
- Connect Streamer.bot to your platform (Twitch / YouTube, etc.).
- Configure it manually or import a prepared settings file.
- In the documentation folder there is a file `Test_streamerbot` with basic Streamer.bot settings (only triggers and actions for manual launch by a streamer/moderator).
  - These settings are intended for manual triggering by a streamer or moderator.
- For automatic starts (Channel Points, Bits, Poll voting), add additional triggers to the Action:
  - Channel Points → Twitch → Channel Reward → Redeemed (SOURCE=2)
  - Bits → Twitch → Cheer (SOURCE=1)
  - Votes → Twitch → Polls → Poll Ended/Completed (SOURCE=3)
  - For donations, manual execution via a regular command trigger or `force` is recommended.
- To create new triggers, open **Commands** and add a trigger as needed (or follow the pattern of existing ones).
- To create new commands, open **Actions** and create a new action (you can duplicate an existing one and modify it).
- IMPORTANT: to create working queues, open **Queues**, create a new queue, and then assign that queue to the relevant Actions.
- When creating new commands, note that they should start with `normal` or `force` (all commands are listed in `README.txt` in the TDL folder).


# Русская версия
## Настройка Streamer.bot

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Настройка Streamer.bot: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

Этот документ помогает настроить локальный чат-бот **Streamer.bot**.


---

## Настройка Streamer.bot

- Для начала скачайте Streamer.bot с официального сайта.
- Авторизуйтесь в приложении.
- Подключите Streamer.bot к вашей платформе (Twitch / YouTube и т. п.).
- Настройте всё вручную или импортируйте подготовленный файл с настройками.
- В папке документации есть файл `Test_streamerbot` с базовыми настройками Streamer.bot (только триггеры и Actions для ручного запуска стримером/модератором).
  - Эти настройки рассчитаны на ручной запуск по триггеру стримером или модератором.

### Автоматический запуск (баллы канала / Bits / голосование)

Для автоматического запуска при покупке баллов канала, Bits или завершении голосования добавьте дополнительные триггеры в нужный Action:
- Channel Points → Twitch → Channel Reward → Redeemed (SOURCE=2)
- Bits → Twitch → Cheer (SOURCE=1)
- Votes → Twitch → Polls → Poll Ended/Completed (SOURCE=3)

Для донатов обычно рекомендуется ручной запуск через триггер обычной команды или через `force`.

### Создание новых триггеров / Actions / очередей

- Для создания новых триггеров зайдите в раздел **Commands** и добавьте триггер по вашей необходимости (или по образцу уже созданных).
- Для создания новых команд перейдите в раздел **Actions** и создайте новый Action (можно дублировать существующий и изменить его).
- Важно: для корректной работы очередей перейдите в раздел **Queues**, создайте новую очередь, затем назначьте её нужным Actions.

При создании новых команд обратите внимание: они должны начинаться с `normal` или `force` (все команды перечислены в файле `README.txt` в папке TDL).
