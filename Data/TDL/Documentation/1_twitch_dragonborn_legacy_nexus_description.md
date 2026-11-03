# Twitch Dragonborn Legacy (TDL)

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
TDL turns your Twitch viewers into the gods (and demons) of your Skyrim run. Channel point rewards, bits,
chat commands and polls trigger scenarios in the game: divine wrath, summoned monsters and dragons, a hunter
on your trail, horror chases, arenas, curses, teleports, weather and size changes.

TDL is **not** a questline. It is a toolbox of staged scenarios built for live streams and challenge runs.

---

## Key features

- **Direct Twitch connection** built into the SKSE plugin (since 1.1): no Streamer.bot, no external programs
- One-time login with a code at twitch.tv/activate; the token is stored encrypted for your Windows user
- Rewards, bits, chat commands and polls mapped to actions in one file: `Data\SKSE\Plugins\TDL_Twitch.ini`
- Difficulty tiers: a reward can pick a random action from a list
- In-game messages show who did what ("Vasya summoned a dragon!")
- Smart queue: per-group cooldowns, priorities (bits > points/chat > polls), no effect spam
- 46 actions in 11 modules: Wrath, Healing/Blessing, Summoning, Hunter, Show, Chaos, Inventory,
  Teleport (with a built-in fast-respawn window), Virus, Weather, Gigant
- **Multilingual out of the box**: all texts (MCM, effects, names, messages, menus) follow your game language - 9 languages, no translation files needed

---

## Requirements

See `2_twitch_dragonborn_legacy_installation_and_requirements.md` (single source of truth).

---

## Safety

The mod ships **no executables**. Twitch is reached by the SKSE plugin over HTTPS (Twitch API / EventSub).
The plugin is open source (GPL-3.0): https://github.com/Granit1846/SkyrimAE

## Support the author

If you enjoy the mod and want to say thanks: https://boosty.to/skeorz

---

# Русская версия

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
TDL превращает зрителей вашего Twitch в богов (и демонов) вашего прохождения Skyrim. Награды за баллы канала,
биты, команды чата и голосования запускают сценарии в игре: божественную кару, призыв чудовищ и драконов,
охотника по вашему следу, хоррор-погони, арены, проклятия, телепорты, смену погоды и размеров.

TDL - **не квест**. Это набор сценариев для стримов и челленджей.

---

## Ключевые особенности

- **Прямое подключение к Twitch** внутри SKSE-плагина (с 1.1): без Streamer.bot и сторонних программ
- Одноразовый вход по коду на twitch.tv/activate, токен хранится в зашифрованном виде для вашего пользователя Windows
- Награды, биты, команды чата и голосования настраиваются в одном файле: `Data\SKSE\Plugins\TDL_Twitch.ini`
- Уровни сложности: награда может выбирать случайное действие из списка
- Сообщения в игре о том, кто что сделал («Вася призвал дракона!»)
- Умная очередь: кулдауны по группам, приоритеты (биты > баллы/чат > голосования), без спама эффектами
- 46 действий в 11 модулях: Кара, Лечение/Благословение, Призыв, Охотник, Шоу, Хаос, Инвентарь,
  Телепорт (со встроенным окном быстрого респауна), Вирус, Погода, Гигант
- **Мультиязычность «из коробки»**: все тексты (MCM, эффекты, имена, сообщения, меню) следуют языку игры - 9 языков, отдельные переводы не нужны

---

## Требования

См. `2_twitch_dragonborn_legacy_installation_and_requirements.md` (основной документ).

---

## Безопасность

В моде **нет исполняемых файлов**. С Twitch работает SKSE-плагин по HTTPS (Twitch API / EventSub).
Исходный код плагина открыт (GPL-3.0): https://github.com/Granit1846/SkyrimAE

---

## Поддержать автора

Если мод вам нравится и вы хотите поблагодарить автора: https://boosty.to/skeorz
