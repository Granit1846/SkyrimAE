# Twitch Dragonborn Legacy (TDL)
## FAQ & Known Issues

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

## FAQ

### Do I still need Streamer.bot or tdl_send.exe?
No. Since 1.1 the SKSE plugin talks to Twitch directly. Remove old TDL actions from Streamer.bot so commands are not sent twice.

### Do I need Twitch Affiliate/Partner?
Only for channel points and bits - Twitch does not offer them to other channels. Chat commands and polls work on any account.

### Who can use chat commands?
The broadcaster and moderators. Set `ChatAllowEveryone=1` in `TDL_Twitch.ini` to open them to everyone.

### How do I log out / switch accounts?
Delete `Documents\My Games\Skyrim Special Edition\SKSE\TDL_Twitch.token` and restart the game.

### Is my Twitch password stored?
No. You log in on twitch.tv; the mod only keeps a refresh token, encrypted with Windows DPAPI for your Windows user.

### Do I need a new game?
No. Updating from 1.0.x keeps saves working.

---

## Known issues / troubleshooting

### "failed to open address library file" on start
Address Library does not match your game version (e.g. after a Skyrim update). Install the Address Library file for your version.

### A plugin "must be recompiled for new address library" (ConsoleUtilSSE)
An old ConsoleUtilSSE build. Install ConsoleUtilSSE NG with support for your game version.

### Commands from chat do nothing
1. Check the log `TDL_StreamPlugin.log`: "Twitch: logged in as ..." and "4 of 4 subscriptions active".
2. A line "Twitch: !cmd by ... -> ACTION" means the command arrived; "no mapping" means the command/reward title is not in the INI.
3. Remember the cooldowns: a group waits before the next action ("Queue: PUSH ...").

### The login code window appeared but I closed it
Restart the game - a new code is shown. The code is valid for 30 minutes.

### Low gravity: the character hangs in the air
Fixed in 1.1.7 (a short "nudge" when the player stalls mid-air during the low-gravity effect).

---

# Русская версия
## FAQ и известные проблемы

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

## FAQ

### Нужны ли ещё Streamer.bot или tdl_send.exe?
Нет. С 1.1 SKSE-плагин сам работает с Twitch. Уберите старые действия TDL из Streamer.bot, чтобы команды не приходили дважды.

### Нужен ли статус компаньона/партнёра Twitch?
Только для баллов канала и битов - другим каналам Twitch их не даёт. Команды чата и голосования работают на любом аккаунте.

### Кто может использовать команды чата?
Стример и модераторы. `ChatAllowEveryone=1` в `TDL_Twitch.ini` открывает их всем.

### Как выйти / сменить аккаунт?
Удалите `Документы\My Games\Skyrim Special Edition\SKSE\TDL_Twitch.token` и перезапустите игру.

### Хранится ли мой пароль Twitch?
Нет. Вход выполняется на twitch.tv; мод хранит только токен обновления, зашифрованный Windows DPAPI для вашего пользователя.

### Нужна ли новая игра?
Нет. При обновлении с 1.0.x сохранения работают.

---

## Известные проблемы / решение

### «failed to open address library file» при запуске
Address Library не подходит к версии игры (например, после обновления Skyrim). Установите файл Address Library под вашу версию.

### Плагин «must be recompiled for new address library» (ConsoleUtilSSE)
Старая сборка ConsoleUtilSSE. Установите ConsoleUtilSSE NG с поддержкой вашей версии игры.

### Команды из чата ничего не делают
1. Проверьте журнал `TDL_StreamPlugin.log`: «Twitch: logged in as ...» и «4 of 4 subscriptions active».
2. Строка «Twitch: !cmd by ... -> ACTION» значит, что команда дошла; «no mapping» - команды/названия награды нет в INI.
3. Помните о кулдаунах: группа ждёт перед следующим действием («Queue: PUSH ...»).

### Появилось окно с кодом, но я его закрыл
Перезапустите игру - будет новый код. Код действует 30 минут.

### Низкая гравитация: персонаж зависает в воздухе
Исправлено в 1.1.7 (короткий «толчок», когда персонаж застывает в воздухе во время эффекта).
