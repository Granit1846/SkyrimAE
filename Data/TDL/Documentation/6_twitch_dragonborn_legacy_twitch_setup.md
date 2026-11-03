# Twitch Dragonborn Legacy (TDL)
## Twitch connection & TDL_Twitch.ini

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Twitch connection & TDL_Twitch.ini: `6_twitch_dragonborn_legacy_twitch_setup.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

> - Stream features (1.2): `9_twitch_dragonborn_legacy_stream_features.md`  
---

## Login (once)

1. Start the game through SKSE. A message box shows a code, and twitch.tv/activate opens in your browser.
2. Log in with the account **you stream from**, enter the code, allow access.
3. Done. The plugin keeps the login encrypted for your Windows user in
   `Documents\My Games\Skyrim Special Edition\SKSE\TDL_Twitch.token` and refreshes it by itself.

Permissions requested: read channel point redemptions, bits, chat and polls of your channel.
To log out or switch accounts, delete `TDL_Twitch.token` and restart the game.

---

## TDL_Twitch.ini

`Data\SKSE\Plugins\TDL_Twitch.ini`, UTF-8. Changes apply while the game is running.

### [Twitch]
| Key | Default | Meaning |
|---|---|---|
| Enabled | 1 | 0 = do not connect to Twitch |
| ChatAllowEveryone | 0 | 1 = chat commands from everyone, 0 = broadcaster and moderators only |
| Notify | 1 | in-game messages from `[Messages]` |
| PollName | Чат | name used in messages for poll results |
| MockServer | 0 | 1 = test with the Twitch CLI mock EventSub server |
| MockUrl | ws://127.0.0.1:8080/ws | address of the mock server |

### Mapping sections
| Section | Key | Example |
|---|---|---|
| [Rewards] | exact reward title | `TDL: Тяжёлое испытание=SUMMON_STRONG, WRATH_11, COMEDY_HORROR` |
| [Bits] | minimum amount (largest threshold not above the cheer wins) | `500=SUMMON_ANY, WEATHER_STORM` |
| [Chat] | command | `!tdl_heal=SYSTEM_HEALING` |
| [Poll] | winning choice title | `Дракон=SUMMON_DRAGON` |

A value is one action, a comma-separated list (one is picked at random), or a burst `FORCE|SUMMON_SKELETON|3`.
All action IDs are listed in `Data\TDL\README.txt`.

### [Messages]
`ACTION=text` shown in the top-left corner when the action fires. `{user}` = viewer name, `{trigger}` = the reward
title / "500 bits" / chat command. Actions without a line show `{user}: {trigger}`.
The defaults are Russian - translate them into your stream language.

---

# Русская версия
## Подключение Twitch и TDL_Twitch.ini

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Подключение Twitch и TDL_Twitch.ini: `6_twitch_dragonborn_legacy_twitch_setup.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

> - Стрим-функции (1.2): `9_twitch_dragonborn_legacy_stream_features.md`  
---

## Вход (один раз)

1. Запустите игру через SKSE. Появится окно с кодом, а в браузере откроется twitch.tv/activate.
2. Войдите в аккаунт, **с которого стримите**, введите код и разрешите доступ.
3. Готово. Плагин хранит вход в зашифрованном виде для вашего пользователя Windows в
   `Документы\My Games\Skyrim Special Edition\SKSE\TDL_Twitch.token` и сам его обновляет.

Запрашиваемые права: чтение наград за баллы, битов, чата и голосований вашего канала.
Чтобы выйти или сменить аккаунт, удалите `TDL_Twitch.token` и перезапустите игру.

---

## TDL_Twitch.ini

`Data\SKSE\Plugins\TDL_Twitch.ini`, UTF-8. Изменения применяются прямо во время игры.

### [Twitch]
| Ключ | По умолчанию | Значение |
|---|---|---|
| Enabled | 1 | 0 = не подключаться к Twitch |
| ChatAllowEveryone | 0 | 1 = команды чата от всех, 0 = только стример и модераторы |
| Notify | 1 | сообщения в игре из `[Messages]` |
| PollName | Чат | от чьего имени объявляются итоги голосования |
| MockServer | 0 | 1 = тестирование с mock-сервером EventSub из Twitch CLI |
| MockUrl | ws://127.0.0.1:8080/ws | адрес mock-сервера |

### Разделы привязок
| Раздел | Ключ | Пример |
|---|---|---|
| [Rewards] | точное название награды | `TDL: Тяжёлое испытание=SUMMON_STRONG, WRATH_11, COMEDY_HORROR` |
| [Bits] | минимальная сумма (срабатывает наибольший порог, не выше суммы) | `500=SUMMON_ANY, WEATHER_STORM` |
| [Chat] | команда | `!tdl_heal=SYSTEM_HEALING` |
| [Poll] | название победившего варианта | `Дракон=SUMMON_DRAGON` |

Значение - одно действие, список через запятую (выбирается случайное) или серия `FORCE|SUMMON_SKELETON|3`.
Все идентификаторы действий перечислены в `Data\TDL\ПРОЧТИ МЕНЯ.txt`.

### [Messages]
`ACTION=текст`, который появляется в левом верхнем углу, когда действие срабатывает. `{user}` - ник зрителя,
`{trigger}` - название награды / «500 bits» / команда чата. Для действий без строки показывается `{user}: {trigger}`.
