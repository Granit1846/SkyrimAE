# Twitch Dragonborn Legacy (TDL)
## For streamers & interactive control

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

## How viewers interact

| Twitch | Priority | Who | Needs |
|---|---|---|---|
| Bits (cheer) | highest | anyone | Affiliate/Partner |
| Channel point rewards | normal | anyone | Affiliate/Partner |
| Chat commands (`!tdl_heal`) | normal | broadcaster + mods (or everyone) | any account |
| Polls (winning choice) | lowest | the chat as a whole | any account |

Every event is mapped to an action (or a random action from a tier) in `TDL_Twitch.ini` -
see `6_twitch_dragonborn_legacy_twitch_setup.md`. In the game a message shows who did it.

---

## Suggested setup for a stream

1. Create four channel point rewards with the titles from `[Rewards]`
   (`TDL: Лёгкое испытание` ... `TDL: Эпическое испытание`) or rename them in the INI to your own titles.
   Turn on "Skip reward requests queue" if you do not want to approve them manually.
2. Keep the default bits tiers (100 / 500 / 1000 / 2500) or change the thresholds.
3. Use chat commands for yourself and your moderators: healing, weather/size reset, test ping.
4. Polls: name the choices like the `[Poll]` keys (e.g. Дракон / Охотник / Арена) - the winner is triggered when the poll ends.

---

## Queue, cooldowns, safety

- Each group (summon, weather, teleport, show...) fires one action, then waits for its cooldown;
  the rest of the group waits in the queue (15 per group, 8 for virus/show/inventory).
- Higher priority (bits) goes first; when a group queue is full, a higher-priority action replaces the lowest one.
- Cooldowns: `Data\TDL\config\TDL_Cooldowns.ini` (read at game start).
- Werewolf, vampire lord and "drop all items" are hard to undo - keep them for epic tiers or leave them out.
- FORCE bursts ignore cooldowns and can overload the engine (FPS drops, crashes). Use them yourself, not from chat.

---

## Stream UX tips

- Start with light tiers and open heavier ones as the stream warms up.
- Put the action names in your reward descriptions so viewers know what they buy.
- The in-game message line is visible on stream - translate `[Messages]` into your stream language.

---

# Русская версия
## Для стримеров и интерактива

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

## Как зрители влияют на игру

| Twitch | Приоритет | Кто | Нужно |
|---|---|---|---|
| Биты (cheer) | самый высокий | любой | компаньон/партнёр |
| Награды за баллы канала | обычный | любой | компаньон/партнёр |
| Команды чата (`!tdl_heal`) | обычный | стример + модераторы (или все) | любой аккаунт |
| Голосования (победивший вариант) | самый низкий | весь чат | любой аккаунт |

Каждое событие привязывается к действию (или к случайному действию из уровня) в `TDL_Twitch.ini` -
см. `6_twitch_dragonborn_legacy_twitch_setup.md`. В игре появляется сообщение, кто это сделал.

---

## Рекомендуемая настройка стрима

1. Создайте четыре награды за баллы с названиями из `[Rewards]`
   (`TDL: Лёгкое испытание` ... `TDL: Эпическое испытание`) или впишите в INI свои названия.
   Включите «Пропускать очередь запросов», если не хотите подтверждать награды вручную.
2. Оставьте пороги битов по умолчанию (100 / 500 / 1000 / 2500) или поменяйте их.
3. Команды чата - для вас и модераторов: лечение, сброс погоды/размера, проверка связи.
4. Голосования: назовите варианты как ключи `[Poll]` (например, Дракон / Охотник / Арена) - победитель срабатывает по окончании.

---

## Очередь, кулдауны, безопасность

- Каждая группа (призыв, погода, телепорт, шоу...) выполняет одно действие и ждёт кулдаун;
  остальные действия группы стоят в очереди (15 на группу, 8 для вируса/шоу/инвентаря).
- Более высокий приоритет (биты) идёт первым; если очередь группы полна, он вытесняет самое низкоприоритетное действие.
- Кулдауны: `Data\TDL\config\TDL_Cooldowns.ini` (читается при запуске игры).
- Оборотень, лорд-вампир и «потеря всего инвентаря» плохо отменяются - держите их для эпических уровней или уберите.
- Серии FORCE не учитывают кулдауны и могут перегрузить движок (просадки FPS, вылеты). Запускайте их сами, не из чата.

---

## Советы по стриму

- Начинайте с лёгких уровней и открывайте тяжёлые по ходу стрима.
- Пишите в описании награды, что она делает, чтобы зрители знали, за что платят.
- Строка сообщений в игре видна на стриме - переведите `[Messages]` на язык вашего стрима.
