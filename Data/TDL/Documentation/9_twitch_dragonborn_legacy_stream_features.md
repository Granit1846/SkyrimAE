# TDL 1.2.0 — Stream Features Guide

TDL 1.2.0 connects Skyrim Special Edition directly to Twitch via an SKSE plugin (no third-party bot software required). Configuration is stored in `Data/SKSE/Plugins/TDL_Twitch.ini` (UTF-8) and updates automatically while the game is running without restarting.

---

### 1. OBS Overlay (`[Overlay]`)

TDL provides a built-in web server displaying the action queue, current event timer, and stream status directly inside OBS.

- **URL:** `http://127.0.0.1:8645/`
- **OBS Setup (recommended):**
  1. Add a **Browser** source in OBS and tick **Local file**.
  2. Choose `Skyrim Special Edition\Data\SKSE\Plugins\TDL_Overlay.html` (with MO2: the file inside the mod folder).
  3. Set dimensions: **Width: 440**, **Height: 600**.
  4. The page works even if OBS starts before the game: it shows "offline" and connects by itself when the game is running.
- **Alternative:** URL `http://127.0.0.1:8645/` works only while the game is running; if OBS was started first, press **Refresh** on the source.
- If you changed `Port`, use the URL variant.- **Features:** Shows active queue slots, countdowns (ETA), and a prominent **PAUSED** badge whenever the streamer pauses integration.

```ini
[Overlay]
Enabled=1
Port=8645
```

---

### 2. Chat Replies & Help Command (`[ChatReplies]`)

TDL can send Twitch chat messages to confirm queued actions, warn when the queue is saturated, and provide a command list.

- **Available Placeholders:**
  - `{user}` — Viewer's Twitch handle.
  - `{trigger}` — Action name, reward title, bits count, or chat command.
  - `{pos}` — Position in the execution queue.
  - `{eta}` — Estimated seconds until trigger execution.
  - `{refund}` — Injects the `Refunded` text if channel points were returned.
- **Help Command:** Viewers type `!tdl` to see available rewards, bit tiers, and chat commands configured in your INI.

```ini
[ChatReplies]
Enabled=1
; Sent when an action enters the queue (5+ s delay)
Queued=@{user}, {trigger}: queued at #{pos}, ~{eta}s
; Immediate triggers (leave empty to rely only on in-game notification)
Now=
; Trigger rejected due to a full queue
Dropped=@{user}, {trigger}: queue is full, please try again later. {refund}
; Replaced by a higher-priority trigger (e.g. bits over channel points)
Evicted=@{user}, {trigger}: replaced by a higher-tier event. {refund}
; Text appended to {refund} in drop/evict notices
Refunded=Channel points refunded.
HelpCommand=!tdl
Help=Rewards: {rewards} | Bits: {bits} | Commands: {commands}
```

---

### 3. Auto-Created Rewards & Automatic Refunds (`CreateRewards`)

> **Requirement:** Twitch Affiliate or Partner status.

Twitch API allows third-party tools to refund or cancel redemptions **only if the tool created the reward**. Manual rewards created via the Twitch Creator Dashboard cannot be automatically refunded by TDL when the queue is full.

- Set `CreateRewards=1` in `[Twitch]`.
- Define reward names under `[Rewards]` and point values under `[RewardCosts]`.
- On startup, TDL registers these custom rewards via the Twitch API.
- If an action is dropped or rejected, points are returned to the viewer instantly (`CANCELED` status).

```ini
[Twitch]
Enabled=1
CreateRewards=1

[Rewards]
TDL: Easy Trial=WEATHER_CLEAR, WEATHER_RAIN, SUMMON_SKELETON
TDL: Epic Trial=SUMMON_DRAGON, HUNTER_START

[RewardCosts]
TDL: Easy Trial=500
TDL: Epic Trial=10000
```

---

### 4. Streamer Pause

Allows the streamer or moderators to temporarily halt Twitch-triggered events during dialogue, cutscenes, or difficult encounters.

- **Chat Commands (Broadcaster & Mods only):**
  - `!tdl pause` or `!tdl_pause` — Pauses Twitch integration.
  - `!tdl resume` or `!tdl_resume` — Resumes processing.
- **INI Setting:** `Paused=1` inside `[Twitch]`. Hot-reloading detects changes immediately.
- **Pause Behavior:**
  - Channel point redemptions are rejected and immediately refunded.
  - Bits, polls, and chat commands are rejected with a chat notice (`TDL paused`).
  - Local/pipe commands (e.g., debug console) continue to function.
  - The OBS overlay displays a `PAUSED` banner.
  - An in-game notification displays on state change.

```ini
[Twitch]
; 0 = active, 1 = paused
Paused=0
```

---

**Pause mode** (`[Twitch] PauseMode`): `cancel` (default) - commands sent during a pause are rejected (points refunded); `hold` - they wait in the queue and run in order after `!tdl resume` (queue limits and anti-spam still apply; a running summon burst continues after resume). Auto-poll votes are cancelled by a pause in both modes.

### 5. Stream-Safe Defaults (`[Safety]`)

Prevents catastrophic game disruptions or soft-locks from viewer actions without impacting manual console/pipe commands.

- **`Blocked`:** Comma-separated list of prohibited action identifiers.
  - If a randomized reward pool includes a blocked item, TDL discards it and rolls from remaining allowed actions. If all choices are blocked, the reward is rejected and refunded.
- **`AllowForceFromViewers`:** Prevents viewers from sending burst actions (`FORCE|ACTION|COUNT`). Streamer and moderators can still run bursts via chat.

```ini
[Safety]
; Actions blocked from viewer execution via Twitch
Blocked=VIRUS_WEREWOLF, VIRUS_VAMPIRE, INVENTORY_DROP_ALL

; 0 = viewers cannot trigger burst/FORCE syntax; 1 = allowed
AllowForceFromViewers=0
```

---

### 6. Anti-Spam & Rate Limiting (`[AntiSpam]`)

Controls command flooding and prevents single viewers from monopolizing the queue.

- **`UserCooldownSec`:** Per-user cooldown for chat commands. Broadcaster and moderators are exempt. Chat error replies are throttled to at most once per user per cooldown window.
- **`MaxQueuedPerUser`:** Maximum actions a single viewer can have queued at once across all Twitch sources. Redemptions exceeding this limit are refunded.
- **`ExemptBits`:** Allows paid Bits actions to bypass the `MaxQueuedPerUser` restriction.
- **`IgnoreDuplicateSec`:** Drops identical commands from the same user sent within `N` seconds silently.

```ini
[AntiSpam]
; Cooldown between accepted chat commands per user (in seconds)
UserCooldownSec=20

; Maximum actions waiting in queue per individual user
MaxQueuedPerUser=2

; 1 = Cheer/Bits triggers ignore MaxQueuedPerUser
ExemptBits=1

; Silently ignore identical repeated commands within this window (seconds)
IgnoreDuplicateSec=5
```

---
---

### 7. Viewer Statistics

Tracks lifetime viewer engagement metrics based on Twitch User ID (persisting across username changes).

> [!NOTE]
> **Tracked Data:**
> - Successfully executed actions (counted only when triggered via the outcome hook, not merely submitted).
> - Total Bits cheered.
> - Channel Point redemptions.
> - Last seen timestamp.

#### Storage & Reliability
- **File path:** `Documents\My Games\Skyrim Special Edition\SKSE\TDL_Stats.json` (stored alongside the authentication token).
- **Save behavior:** Loaded at startup; written at most once every 30 seconds if modified, and saved cleanly on shutdown. Writes to a temporary file before renaming to prevent corruption.
- **Fail-safe:** If the JSON file is corrupted, the mod logs an error, renames the damaged file to `TDL_Stats.json.bad`, and initializes a clean stats file without crashing.

#### Chat Commands
| Command | Permission | Description |
| :--- | :--- | :--- |
| `!tdl top` | Everyone | Displays the top 5 viewers ranked by executed actions. |
| `!tdl me` | Everyone | Displays the sender's personal stats (actions, bits, redemptions). |

*Responses are posted as a single chat message and automatically respect chat length limits.*

#### Overlay Integration
- `/state` returns `"top": [{"name": "ViewerName", "actions": 12}, ...]`.
- `TDL_Overlay.html` contains a dedicated "Top viewers" leaderboard block that hides automatically when empty or disabled.

#### INI Configuration (`TDL_Twitch.ini`)
```ini
[Stats]
; Enable tracking and statistics chat commands
Enabled=1
; Reset all stats back to 0 on game startup (useful for event streams)
ResetOnStart=0

[Overlay]
; Show/hide top viewers block in TDL_Overlay.html (1 = show, 0 = hide)
ShowTop=1
```

---

### 8. Raids, Subscriptions, and Hype Train

Integrates Twitch channel milestone events via EventSub to trigger in-game actions with bit-level priority (Source 1).

> [!IMPORTANT]
> - **Account Requirements:** Raids work for **all Twitch accounts**. Subscriptions and Hype Train require **Twitch Affiliate or Partner** status.
> - **Re-login Required:** After updating, re-authorize via the login prompt (`/login`) to grant new scopes: `channel:read:subscriptions` and `channel:read:hype_train`.
> - **Graceful Fallback:** If subscription or Hype Train endpoints fail (e.g., on non-Affiliate accounts), the mod logs a warning and keeps raid handling intact without disconnecting.

#### Event Mapping
- Supported events: `channel.raid`, `channel.subscribe`, `channel.subscription.message` (resubs), `channel.subscription.gift`, `channel.hype_train.begin`, `channel.hype_train.progress` (triggers on level increase only).
- In-game notifications and chat replies support the `{user}` placeholder (raider, subscriber, gifter, or `"Anonymous"`).

#### Testing with Twitch CLI
The mod's mock WebSocket (`MockUrl`) accepts standard Twitch CLI test events:
```bash
twitch event trigger channel.raid --transport=websocket
twitch event trigger channel.subscribe --transport=websocket
twitch event trigger channel.hype-train-begin --transport=websocket
twitch event trigger channel.hype-train-progress --transport=websocket
```

#### INI Configuration (`TDL_Twitch.ini`)
```ini
[Events]
; Comma-separated actions or a single action ID. Leave empty to ignore.
Raid=SUMMON_ANY
; Minimum raid viewer count required to trigger the Raid action
RaidMinViewers=5

; Direct channel subscriptions and resubs
Sub=SYSTEM_BLESSING
Resub=SYSTEM_BLESSING

; Community gift subs
GiftSub=SUMMON_ANY
; 0 = trigger one action for the entire gift bundle; 1 = trigger per individual gift
GiftSubPerGift=0
; Maximum action executions per gift batch when GiftSubPerGift=1
GiftSubMax=5

; Hype Train triggers
HypeTrainBegin=WEATHER_STORM
; Triggers each time the Hype Train advances to a higher level
HypeTrainLevel=SUMMON_STRONG
```

---

### 9. Auto-Polls (Chat Voting)

Periodic automated polls allowing chat to vote on upcoming in-game events.

> [!NOTE]
> - **Universal Compatibility:** Works on **any Twitch channel** (Affiliate status not required).
> - **Stream-Safe:** Automatically excludes any action IDs listed under `[Safety] Blocked`.
> - **Fair Voting:** Votes are simple messages (`!1`, `!2`, `!3`). Free for all chatters (bypasses `ChatAllowEveryone` restrictions and anti-spam cooldowns). One vote per user; the latest vote overrides previous ones.

#### Flow & Behavior
1. Every `IntervalMin` minutes (while unpaused and Twitch is connected), the mod selects `Choices` unique actions from `Pool`.
2. Chat announcement: `"Голосование: 1) <label> 2) <label> 3) <label> - пишите !1 !2 !3 (60 с)"`.
3. When time expires:
   - If total votes are below `MinVotes`, chat is notified that the poll expired with no votes, and nothing runs.
   - The winning action executes with poll source priority (Source 3) and `{user} = PollName`. Ties are resolved randomly.
4. Pausing the game immediately cancels any active vote.

#### Streamer & Moderator Commands
| Command | Permission | Description |
| :--- | :--- | :--- |
| `!tdl poll` | Streamer / Mod | Immediately starts an auto-poll without waiting for the timer. |
| `!tdl poll stop` | Streamer / Mod | Cancels the currently active poll without executing any action. |

#### Overlay Integration
- `/state` includes `"vote": {"options": [{"label": "Storm", "votes": 4}], "secondsLeft": 45}` (or `null` when idle).
- `TDL_Overlay.html` displays an active progress bar with vote counts and countdown timer.

#### INI Configuration (`TDL_Twitch.ini`)
```ini
[AutoPoll]
; Enable automated chat polls
Enabled=0
; Interval between polls in minutes
IntervalMin=10
; Duration of each poll in seconds
DurationSec=60
; Number of options presented per poll
Choices=3
; Minimum total votes required to execute the winning action
MinVotes=1
; Stream-safe pool of action IDs (blocked actions in [Safety] are ignored)
Pool=WEATHER_STORM, SUMMON_ANIMAL, GIGANT_SMALL, SPAWN_CHEST, SPEED_BOOST
```

---

---

### 8a. Raid progression

TDL dynamically scales Twitch raid events based on incoming raid size using the `[RaidTiers]` system. When populated, `[RaidTiers]` takes precedence over `[Events] Raid` (provided viewer count meets `RaidMinViewers`). Settings are hot-reloaded when the INI file is saved.

#### Tier Selection & Evaluation
* **Active Tier:** The highest configured threshold where `Threshold <= Viewers` is selected.
* **Creature Cap:** Total spawned creatures cannot exceed **50** per raid.
* **Cooldowns:** Existing action group cooldowns still apply.

#### Tier Grammar & Syntax
* `+` (Sequence): Executes all parts in order (e.g. `PartA + PartB`).
* `,` (Choice): Selects one part/group at random (e.g. `PartA, PartB`).
* `ACTION|MIN|MAX`: Spawns a count interpolated linearly between `MIN` and `MAX` as viewer count scales from current threshold to the next threshold.
* `ACTION|/N|MAX`: Used in the highest tier. Computes `viewers / N` (minimum 1), capped at `MAX`.
* `RANDOM(poolOrList)|MIN|MAX`: Selects actions at random from a named pool in `[RaidPools]` (case-insensitive) or an inline comma-separated list `RANDOM(ACT1, ACT2)`, executing `MIN..MAX` times.
* `FORCE1|ACTION`: Bypasses normal batching/cooldown constraints to immediately execute single actions (e.g., immediate heals or blessings).

#### Configuration Sections
* **`[RaidPools]`**: Defines reusable action lists (e.g., `wrath = WRATH_11, WRATH_12, WRATH_13`).
* **`[RaidNotices]`**: Displays a custom on-screen notification when reaching a tier threshold (e.g., `201=Ваш чат помогает и благословляет вас!`).
* **`[RaidScaling]`**: Scales creature and random counts according to player level:
  * Multipliers: Level 1 (`0.5x`), Level 11 (`0.75x`), Level 31 (`1.0x`), Level 51 (`1.25x`), Level 76 (`1.5x`).
  * `DragonMinLevel`: Minimum player level required for `SUMMON_DRAGON` (default `20`). If player level is below this threshold, dragons are downgraded to `SUMMON_STRONG`. Set to `0` to disable.

---

#### Default Raid Tiers at Player Level 40
*(Player Level 40 multiplier = `1.0x`; `DragonMinLevel=20` satisfied)*

| Viewers | Active Tier | Triggered Actions & Summons | Notices & Special Effects |
| :---: | :---: | :--- | :--- |
| **5** | `1` | • Instant Heal (`FORCE1\|SYSTEM_HEALING`)<br>• ~5 Skeletons (`SUMMON_SKELETON` [1–10]) | — |
| **20** | `11` | • Instant Heal (`FORCE1\|SYSTEM_HEALING`)<br>• ~6 Animals (`SUMMON_ANIMAL` [3–10]) | — |
| **50** | `31` | • Instant Heal (`FORCE1\|SYSTEM_HEALING`)<br>• ~6 Humanoids (`SUMMON_HUMANOID` [3–10])<br>• ~3 Undead (`SUMMON_UNDEAD` [1–5]) | — |
| **100** | `71` | • Instant Heal (`FORCE1\|SYSTEM_HEALING`)<br>• ~8 Undead (`SUMMON_UNDEAD` [5–10])<br>• ~3 Strong enemies (`SUMMON_STRONG` [1–5])<br>• Wrath tier 11 (`WRATH_11`) | — |
| **150** | `121` | • Instant Heal (`FORCE1\|SYSTEM_HEALING`)<br>• ~7 Strong enemies (`SUMMON_STRONG` [5–10])<br>• 1 Wrath action (`RANDOM(wrath)`) | — |
| **300** | `201` | • Instant Heal (`FORCE1\|SYSTEM_HEALING`)<br>• Instant Blessing (`FORCE1\|SYSTEM_BLESSING`)<br>• 10 Dragons (`300 / 30 = 10`, max 10)<br>• 6 Strong enemies (`300 / 50 = 6`, max 8)<br>• 1–2 Wrath actions (`RANDOM(wrath)`) | Banner: *"Ваш чат помогает и благословляет вас!"* |

---

**Test raid:** `!tdl raid <viewers> [name]` (broadcaster/moderators) runs the same code as a real raid - use it to try your tiers and scaling.

### 10. Sound cue

The TDL overlay can play an audio alert whenever a new action appears in the Recent events list.

#### INI Configuration (`[Overlay]`)
* `Sound=1`: Enables (1) or disables (0) the sound alert (rate-limited to a maximum of once per second).
* `SoundVolume=60`: Volume level (0–100).
* `SoundFile=`: Filename of an `.mp3`, `.wav`, or `.ogg` placed in the same directory as `TDL_Overlay.html`. Leave empty to use the built-in generated chime.

> [!TIP]
> **OBS Studio Setup:** In your OBS Browser Source properties for `TDL_Overlay.html`, enable **"Control audio via OBS"**. This exposes the overlay sound to the OBS audio mixer, allowing you to monitor cue audio in your headphones, route it to stream output, and adjust levels independently.

---

---

# Русская версия

Руководство пользователя по стрим-функциям TDL 1.2.0 для Skyrim Special Edition. Мод работает напрямую с Twitch через SKSE-плагин (без Streamer.bot). Все настройки находятся в файле `Data/SKSE/Plugins/TDL_Twitch.ini` (кодировка UTF-8) и подхватываются на лету во время игры без перезапуска.

---

### 1. Оверлей для OBS (`[Overlay]`)

TDL содержит встроенный веб-сервер, транслирующий очередь событий, таймеры и статус интеграции в OBS.

- **Адрес источника:** `http://127.0.0.1:8645/`
- **Добавление в OBS (рекомендуется):**
  1. Добавьте источник **Браузер** и отметьте **Локальный файл**.
  2. Выберите `Skyrim Special Edition\Data\SKSE\Plugins\TDL_Overlay.html` (в MO2 — файл в папке мода).
  3. Укажите размер: **Ширина: 440**, **Высота: 600**.
  4. Страница работает, даже если OBS запущен раньше игры: показывает «offline» и сама подключается, когда игра запущена.
- **Другой вариант:** URL `http://127.0.0.1:8645/` работает только при запущенной игре; если OBS открыли раньше, нажмите **Обновить** у источника.
- Если вы меняли `Port`, используйте вариант с URL.- **Возможности:** Отображает список активных действий, оставшееся время до срабатывания (~ETA) и крупную плашку **PAUSED**, когда стример ставит мод на паузу.

```ini
[Overlay]
Enabled=1
Port=8645
```

---

### 2. Ответы в чат и справка `!tdl` (`[ChatReplies]`)

TDL отправляет сообщения в чат Twitch, информируя зрителей о статусе их заказов.

- **Переменные шаблонов:**
  - `{user}` — имя зрителя.
  - `{trigger}` — название награды, команда или сумма битсов.
  - `{pos}` — номер позиции в очереди.
  - `{eta}` — примерное время ожидания в секундах.
  - `{refund}` — подставляет текст из параметра `Refunded`, если баллы были возвращены.
- **Команда справки:** По команде `!tdl` бот выводит в чат список доступных наград, диапазоны битсов и команды.

```ini
[ChatReplies]
Enabled=1
; Действие добавлено в очередь (сработает через 5+ сек.)
Queued=@{user}, {trigger}: в очереди #{pos}, ~{eta} с
; Мгновенное действие (пусто = только экранное уведомление)
Now=
; Очередь переполнена
Dropped=@{user}, {trigger}: очередь переполнена, попробуй позже. {refund}
; Вытеснено более приоритетным триггером (например, битсами)
Evicted=@{user}, {trigger}: вытеснено более ценным действием. {refund}
; Текст для подстановки в {refund}
Refunded=Баллы возвращены.
HelpCommand=!tdl
Help=Награды: {rewards} | Биты: {bits} | Команды: {commands}
```

---

### 3. Автосоздание наград и автовозврат баллов (`CreateRewards`)

> **Требование:** Статус Компаньона (Affiliate) или Партнера Twitch.

Twitch API позволяет возвращать или отменять баллы канала **только у тех наград, которые были созданы самим плагином**. Если награда создана вручную на сайте Twitch, вернуть за неё баллы программно невозможно.

- Установите `CreateRewards=1` в секции `[Twitch]`.
- Настройте список наград в `[Rewards]` и их стоимость в `[RewardCosts]`.
- При старте TDL сам создаст эти награды на канале.
- При переполнении очереди, паузе или сбросе события баллы зрителя автоматически возвращаются (`CANCELED`).

```ini
[Twitch]
Enabled=1
CreateRewards=1

[Rewards]
TDL: Лёгкое испытание=WEATHER_CLEAR, WEATHER_RAIN, SUMMON_SKELETON
TDL: Эпическое испытание=SUMMON_DRAGON, HUNTER_START

[RewardCosts]
TDL: Лёгкое испытание=500
TDL: Эпическое испытание=10000
```

---

### 4. Пауза стримера

Позволяет временно заблокировать срабатывание зрительских действий во время диалогов, кат-сцен или сложных боев.

- **Команды чата (только стример и модераторы):**
  - `!tdl pause` или `!tdl_pause` — включить паузу.
  - `!tdl resume` или `!tdl_resume` — снять паузу.
- **Управление через INI:** параметр `Paused=1` в секции `[Twitch]` (применяется сразу после сохранения файла).
- **Поведение во время паузы:**
  - Награды за баллы отклоняются с немедленным возвратом баллов.
  - Битсы, команды чата и опросы отклоняются с уведомлением в чат («TDL paused»).
  - Локальные команды через пайп/консоль продолжают работать без ограничений.
  - На оверлее появляется плашка `PAUSED`.
  - В игре всплывает уведомление об изменении режима.

```ini
[Twitch]
; 0 = интеграция активна, 1 = на паузе
Paused=0
```

---

**Режим паузы** (`[Twitch] PauseMode`): `cancel` (по умолчанию) - команды во время паузы отклоняются (баллы возвращаются); `hold` - они ждут в очереди и срабатывают по порядку после `!tdl resume` (лимиты очереди и анти-спам действуют; начатая серия призыва продолжится после снятия паузы). Голосование пауза отменяет в обоих режимах.

### 5. Безопасность стрима (`[Safety]`)

Защита от действий, способных сломать прохождение, испортить сохранение или нарушить правила платформы.

- **`Blocked`:** Список действий через запятую, запрещенных для запуска через Twitch.
  - Если заблокированное действие входит в группу случайного выбора (`A, B, C`), TDL автоматически выбирает из оставшихся разрешенных. Если разрешенных не осталось — запрос отклоняется с возвратом баллов.
- **`AllowForceFromViewers`:** Запрещает зрителям вызывать серию действий (`FORCE|ACTION|COUNT`). Стример и модераторы по-прежнему могут использовать FORCE через `[Chat]`.
- Локальные вызовы и скрипты через пайп остаются доступны без ограничений.

```ini
[Safety]
; Запрещенные для зрителей действия
Blocked=VIRUS_WEREWOLF, VIRUS_VAMPIRE, INVENTORY_DROP_ALL

; 0 = запретить зрителям вызовы FORCE; 1 = разрешить
AllowForceFromViewers=0
```

---

### 6. Защита от спама (`[AntiSpam]`)

Ограничивает частоту команд и защищает очередь от монополизации одним зрителем.

- **`UserCooldownSec`:** Индивидуальный кулдаун на команды чата для каждого зрителя (стример и модераторы игнорируют кулдаун). Сообщения об ошибке кулдауна отправляются не чаще одного раза за окно, предотвращая спам в чате.
- **`MaxQueuedPerUser`:** Максимальное число активных действий в очереди от одного пользователя (суммарно со всех источников Twitch). При превышении награды за баллы возвращаются.
- **`ExemptBits`:** Позволяет донатам битсами игнорировать лимит `MaxQueuedPerUser`.
- **`IgnoreDuplicateSec`:** Полностью игнорирует повтор одной и той же команды от пользователя, если она отправлена в течение `N` секунд (без спама в чат).

```ini
[AntiSpam]
; Кулдаун между командами чата для одного зрителя (в секундах)
UserCooldownSec=20

; Максимум активных действий в очереди от одного пользователя
MaxQueuedPerUser=2

; 1 = донаты битсами игнорируют лимит MaxQueuedPerUser
ExemptBits=1

; Окно подавления одинаковых повторных команд (в секундах)
IgnoreDuplicateSec=5
```

> [!IMPORTANT]
> **Обязательно после обновления:**
> Выполните повторную авторизацию аккаунта (команда `/login`), чтобы выдать новые разрешения Twitch: `channel:read:subscriptions` и `channel:read:hype_train`.

---

### 7. Статистика зрителей

Модуль ведет постоянный учет активности зрителей по уникальному Twitch ID (статистика сохраняется даже при смене никнейма).

> [!NOTE]
> **Что учитывается:**
> - Успешно выполненные действия (засчитываются через хук выполнения, а не просто при отправке запроса).
> - Отправленные Bits.
> - Награды за баллы канала (Channel Points).
> - Время последней активности.

#### Сохранение данных
- **Путь к файлу:** `Documents\My Games\Skyrim Special Edition\SKSE\TDL_Stats.json` (рядом с файлом токена).
- **Логика записи:** Загружается при старте; сохраняется не чаще раза в 30 секунд при наличии изменений и обязательно при выходе из игры. Запись ведется во временный файл с последующим переименованием.
- **Защита от сбоев:** При повреждении структуры JSON игра не вылетает. Файл переименовывается в `TDL_Stats.json.bad`, в лог пишется предупреждение, а статистика создается заново.

#### Команды чата
| Команда | Доступ | Описание |
| :--- | :--- | :--- |
| `!tdl top` | Всем | Показывает топ-5 зрителей по числу сработавших действий. |
| `!tdl me` | Всем | Показывает личную статистику зрителя (действия, биты, баллы). |

*Ответ отправляется одним сообщением с учетом ограничений длины строки Twitch.*

#### Оверлей
- Эндпоинт `/state` передает массив `"top": [{"name": "Ник", "actions": 12}, ...]`.
- `TDL_Overlay.html` содержит блок лидеров «Top viewers», который скрывается, если список пуст или отключен в INI.

#### Настройка в `TDL_Twitch.ini`
```ini
[Stats]
; Включить модуль статистики и команды !tdl top / !tdl me
Enabled=1
; Сбрасывать накопленную статистику в 0 при каждом запуске игры
ResetOnStart=0

[Overlay]
; Отображение топа зрителей в TDL_Overlay.html (1 = включено, 0 = выключено)
ShowTop=1
```

---

### 8. Рейды, подписки и поезд хайпа

Интеграция событий Twitch через единую сессию EventSub. Действия запускаются с наивысшим приоритетом донатов/битов (Source 1).

> [!IMPORTANT]
> - **Требования Twitch:** Рейды работают **на любых каналах**. Подписки и Поезд Хайпа требуют статус **Компаньона (Affiliate)** или **Партнера**.
> - **Обработка ошибок:** Если у стримера нет статуса компаньона, подписки на платные события завершатся предупреждением в логе, но не сломают работу рейдов и счетчик активных подписок.

#### Поддерживаемые события
- `channel.raid` (рейд вашего канала).
- `channel.subscribe`, `channel.subscription.message` (платные подписки и переподписки).
- `channel.subscription.gift` (подарочные подписки).
- `channel.hype_train.begin`, `channel.hype_train.progress` (начало поезда и повышение его уровня).
- В игровых оповещениях и чате доступен макрос `{user}` (ник рейдера, подписчика, дарителя или `"Anonymous"`).

#### Тестирование через Twitch CLI
События корректно эмулируются через мок-сервер плагина:
```bash
twitch event trigger channel.raid --transport=websocket
twitch event trigger channel.subscribe --transport=websocket
twitch event trigger channel.hype-train-begin --transport=websocket
twitch event trigger channel.hype-train-progress --transport=websocket
```

#### Настройка в `TDL_Twitch.ini`
```ini
[Events]
; ID действия или список через запятую. Пустое значение = событие отключено.
Raid=SUMMON_ANY
; Минимальное количество зрителей в рейде для запуска действия
RaidMinViewers=5

; Подписка и продление подписки (Resub)
Sub=SYSTEM_BLESSING
Resub=SYSTEM_BLESSING

; Подарочные подписки
GiftSub=SUMMON_ANY
; 0 = одно действие на всю пачку сабок; 1 = отдельное действие за каждую подаренную сабку
GiftSubPerGift=0
; Максимум действий при GiftSubPerGift=1
GiftSubMax=5

; Старт поезда хайпа
HypeTrainBegin=WEATHER_STORM
; Запуск действия при каждом повышении уровня поезда хайпа
HypeTrainLevel=SUMMON_STRONG
```

---

### 9. Авто-голосования в чате

Автоматический запуск голосований в чате через регулярные интервалы времени.

> [!NOTE]
> - **Доступно всем:** Работает **на любых аккаунтах** без статуса компаньона.
> - **Безопасность:** Список вариантов автоматически очищается от действий, указанных в `[Safety] Blocked`.
> - **Условия голосования:** Любой зритель может проголосовать сообщением `!1`, `!2`, `!3` (не зависит от `ChatAllowEveryone`, не расходует кулдаун антиспама). Засчитывается последний голос пользователя.

#### Логика работы
1. Каждые `IntervalMin` минут (если игра не на паузе и есть связь с Twitch) плагин выбирает `Choices` случайных действий из `Pool`.
2. В чат отправляется объявление: `"Голосование: 1) <label> 2) <label> 3) <label> - пишите !1 !2 !3 (60 с)"`.
3. По окончании таймера:
   - Если отдано меньше `MinVotes` голосов, голосование отменяется сообщением в чат.
   - Победившее действие запускается с источником опроса (Source 3) и именем `{user} = PollName`. При ничьей победитель выбирается случайно.
4. Постановка игры на паузу автоматически отменяет активное голосование.

#### Команды управления (стример и модераторы)
| Команда | Доступ | Описание |
| :--- | :--- | :--- |
| `!tdl poll` | Стример / Модераторы | Запустить внеочередное голосование прямо сейчас. |
| `!tdl poll stop` | Стример / Модераторы | Досрочно отменить текущее голосование. |

#### Оверлей
- Эндпоинт `/state` передает объект `"vote": {"options":[{"label":"...", "votes": 5}], "secondsLeft": 30}` или `null`, когда голосование не идет.
- Оверлей `TDL_Overlay.html` визуализирует процесс голосования в реальном времени.

#### Настройка в `TDL_Twitch.ini`
```ini
[AutoPoll]
; Включить автоматические голосования
Enabled=0
; Интервал между голосованиями в минутах
IntervalMin=10
; Длительность голосования в секундах
DurationSec=60
; Количество вариантов на выбор
Choices=3
; Минимальное суммарное число голосов для применения результата
MinVotes=1
; Пул доступных действий (заблокированные в [Safety] исключаются автоматически)
Pool=WEATHER_STORM, SUMMON_ANIMAL, GIGANT_SMALL, SPAWN_CHEST, SPEED_BOOST
```

### 8a. Прогрессия рейдов

TDL динамически масштабирует события Twitch-рейдов в зависимости от количества зрителей с помощью секции `[RaidTiers]`. При заполнении `[RaidTiers]` имеет приоритет над стандартным `[Events] Raid` (если число зрителей не меньше `RaidMinViewers`). Настройки обновляются на лету (hot reload) при сохранении файла INI.

#### Выбор уровня и ограничения
* **Активный уровень:** Выбирается наибольший порог, для которого `Порог <= Число зрителей`.
* **Лимит существ:** Не более **50** суммарно призванных существ за один рейд.
* **Кулдауны:** Групповые кулдауны действий продолжают действовать.

#### Грамматика и синтаксис значений
* `+` (Последовательность): Выполняет все части по порядку (например, `PartA + PartB`).
* `,` (Выбор): Случайно выбирает одну группу из перечисленных через запятую (например, `PartA, PartB`).
* `ACTION|MIN|MAX`: Линейно интерполирует количество от `MIN` до `MAX` по мере роста зрителей от текущего порога к следующему.
* `ACTION|/N|MAX`: Используется в последнем уровне. Количество вычисляется как `зрители / N` (минимум 1, максимум `MAX`).
* `RANDOM(poolOrList)|MIN|MAX`: Случайно выбирает действия из именованного пула `[RaidPools]` (регистр не важен) или из списка через запятую `RANDOM(ACT1, ACT2)`, вызывая их указанное количество раз (`MIN..MAX`).
* `FORCE1|ACTION`: Выполняет одиночное действие немедленно в обход очередей и задержек (например, мгновенное исцеление или благословение).

#### Дополнительные секции INI
* **`[RaidPools]`**: Определяет списки действий (например, `wrath = WRATH_11, WRATH_12, WRATH_13`).
* **`[RaidNotices]`**: Текстовые экранные уведомления при достижении порога зрителей (например, `201=Ваш чат помогает и благословляет вас!`).
* **`[RaidScaling]`**: Масштабирование количества призываемых существ и случайных эффектов от уровня игрока:
  * Множители: Уровень 1 (`0.5x`), Уровень 11 (`0.75x`), Уровень 31 (`1.0x`), Уровень 51 (`1.25x`), Уровень 76 (`1.5x`).
  * `DragonMinLevel`: Минимальный уровень игрока для вызова драконов `SUMMON_DRAGON` (по умолчанию `20`). Если уровень ниже, драконы автоматически заменяются на `SUMMON_STRONG`. Значение `0` отключает проверку.

---

#### Таблица работы стандартных уровней при 40 уровне игрока
*(Множитель для 40 уровня = `1.0x`; условие `DragonMinLevel=20` выполнено)*

| Зрители | Уровень | Вызываемые действия и число призывов | Уведомления и особенности |
| :---: | :---: | :--- | :--- |
| **5** | `1` | • Мгновенное лечение (`FORCE1\|SYSTEM_HEALING`)<br>• ~5 скелетов (`SUMMON_SKELETON` [1–10]) | — |
| **20** | `11` | • Мгновенное лечение (`FORCE1\|SYSTEM_HEALING`)<br>• ~6 животных (`SUMMON_ANIMAL` [3–10]) | — |
| **50** | `31` | • Мгновенное лечение (`FORCE1\|SYSTEM_HEALING`)<br>• ~6 гуманоидов (`SUMMON_HUMANOID` [3–10])<br>• ~3 нежити (`SUMMON_UNDEAD` [1–5]) | — |
| **100** | `71` | • Мгновенное лечение (`FORCE1\|SYSTEM_HEALING`)<br>• ~8 нежити (`SUMMON_UNDEAD` [5–10])<br>• ~3 сильных врага (`SUMMON_STRONG` [1–5])<br>• Эффект гнева 11 (`WRATH_11`) | — |
| **150** | `121` | • Мгновенное лечение (`FORCE1\|SYSTEM_HEALING`)<br>• ~7 сильных врагов (`SUMMON_STRONG` [5–10])<br>• 1 эффект гнева (`RANDOM(wrath)`) | — |
| **300** | `201` | • Мгновенное лечение (`FORCE1\|SYSTEM_HEALING`)<br>• Мгновенное благословение (`FORCE1\|SYSTEM_BLESSING`)<br>• 10 драконов (`300 / 30 = 10`, лимит 10)<br>• 6 сильных врагов (`300 / 50 = 6`, лимит 8)<br>• 1–2 эффекта гнева (`RANDOM(wrath)`) | Сообщение: *"Ваш чат помогает и благословляет вас!"* |

---

**Тестовый рейд:** `!tdl raid <зрители> [имя]` (стример/модераторы) запускает тот же код, что и настоящий рейд - удобно проверять уровни и масштабирование.

### 10. Звуковой сигнал

Оверлей TDL может воспроизводить звуковой сигнал при появлении нового действия в блоке недавних событий (Recent).

#### Параметры INI (`[Overlay]`)
* `Sound=1`: Включение (1) или отключение (0) звукового оповещения (срабатывает не чаще одного раза в секунду).
* `SoundVolume=60`: Громкость сигнала от 0 до 100.
* `SoundFile=`: Имя файла `.mp3`, `.wav` или `.ogg`, расположенного рядом с `TDL_Overlay.html`. Если поле пустое, проигрывается встроенный процедурный перезвон (chime).

> [!TIP]
> **Настройка в OBS Studio:** В свойствах источника «Браузер» (Browser Source) для `TDL_Overlay.html` включите пункт **«Управление звуком через OBS»** (*Control audio via OBS*). Это выведет звук оверлея в микшер аудио OBS, позволяя настроить громкость, слушать сигнал в наушниках через мониторинг и передавать его на трансляцию.
