# Twitch Dragonborn Legacy (TDL)
## FAQ & Known Issues

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Streamer.bot setup: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md` 

This file focuses on questions and troubleshooting.  
For installation steps, use: `2_twitch_dragonborn_legacy_installation_and_requirements.md`.

---

## FAQ

### Does the mod work without the tools folder?
No. The folder **must** exist at: `Data\TDL\tools\` (including `tdl_send.exe`).  
If it is missing, moved, renamed, or quarantined — TDL will not work.

### Why is there an .exe inside the mod?
TDL provides external integration via an included helper tool (`tdl_send.exe`).  
Some antivirus products may flag any unsigned executable. If it is blocked/quarantined, restore it and add an exclusion.

### Do I need SkyUI?
SkyUI is recommended for MCM settings. Without it, configuration is limited.

### Do I need a new game?
No, a new game is not required.

---

## Known issues / troubleshooting

### The mod “does nothing”
1. Verify the SKSE plugin is installed:
   - `Data\SKSE\Plugins\TDL_StreamPlugin.dll`
2. Verify tools exist:
   - `Data\TDL\tools\tdl_send.exe`
3. If antivirus quarantined the tool, restore it and add an exclusion.

### MCM is missing
Install SkyUI and ensure it loads correctly.

### Antivirus / antimalware blocks the tool
Add an exclusion for the mod folder and restore the file. Do not rename it and do not move it.

---

# Русская версия
## FAQ и известные проблемы

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Настройка Streamer.bot: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`   

Этот файл — про вопросы и устранение неполадок.  
Инструкции по установке и требованиям: `2_twitch_dragonborn_legacy_installation_and_requirements.md`.

---

## FAQ

### Работает ли мод без папки tools?
Нет. Папка **обязана** существовать по пути: `Data\TDL\tools\` (включая `tdl_send.exe`).  
Если папка отсутствует, перенесена, переименована или файл был удалён антивирусом — TDL работать не будет.

### Почему в составе мода есть .exe?
TDL использует внешний инструмент (`tdl_send.exe`) для интеграции и внешнего взаимодействия.  
Некоторые антивирусы могут реагировать на неподписанные exe. Если файл заблокирован/удалён — восстановите его и добавьте исключение.

### Нужен ли SkyUI?
SkyUI рекомендуется для настройки через MCM. Без SkyUI возможности настройки будут ограничены.

### Нужна ли новая игра?
Нет, начинать новую игру не требуется.

---

## Известные проблемы / устранение неполадок

### “Ничего не происходит”
1. Проверьте наличие SKSE-плагина:
   - `Data\SKSE\Plugins\TDL_StreamPlugin.dll`
2. Проверьте наличие tools:
   - `Data\TDL\tools\tdl_send.exe`
3. Если антивирус удалил/карантинировал файл — восстановите его и добавьте исключение.

### Нет MCM
Установите SkyUI и убедитесь, что он загружается корректно.

### Антивирус блокирует tool
Добавьте исключение для папки мода и восстановите файл. Не переименовывайте и не переносите его.
