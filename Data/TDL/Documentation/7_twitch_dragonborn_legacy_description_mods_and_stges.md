# Twitch Dragonborn Legacy (TDL)
## Mod and stages overview

> **Docs navigation**  
> - Nexus description: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Installation & requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ & known issues: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - What this mod does NOT do: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Streamers & interactive control: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Streamer.bot setup: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Stages overview: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog & roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md` 

This document describes TDL stages/scenarios and their intent.  
Installation and requirements: `2_twitch_dragonborn_legacy_installation_and_requirements.md`.

---

## Overview

**Twitch Dragonborn Legacy (TDL)** is a mod for **Skyrim Special Edition / Anniversary Edition** built as a **command and scenario system**, not a linear quest.

TDL aims to create **tense, unpredictable, and spectacle-driven gameplay**, where the player regularly faces external interventions: sudden events, pressure scenarios, chaotic effects, and survival challenges.

The key feature of the mod is its architecture:

> In TDL, quest stages are used as **commands**, not as progression.

Each stage is an entry point into a specific module. Stages can be triggered:
- from MCM
- from the console
- from external tools
- from streaming integrations

Stages do not form a chain and can be triggered **in any order and repeatedly**.

---

## Stage architecture principles

- **Stage ≠ progression**
- **Stage = command**
- stages do not store state
- each module manages its own logic

Some stages execute an instant action; others start an **asynchronous scenario** that runs over time and ends by conditions.

---

## System stages

### Stage 1 — Init / check
A utility stage to verify the system is active and the controller is available.

### Stage 10 — Ping
Used to check connectivity (MCM, external configurator, stream commands).

---

## Wrath of God

### Stage 11 / 12 / 13
Powerful “divine intervention” scenarios.

- heavy effects
- destructive events
- high impact

Each stage is a separate “wrath” scenario.

---

## Healing and Blessing

### Stage 20 — Healing
A support and recovery scenario.

### Stage 30 — Blessing
A temporary blessing or empowerment.

---

## Summoning

### Stage 40 — Random summon
Picks a random object or creature from the common pool.

### Stage 41–46 — List-based summon
Each stage corresponds to an index in a summon list.

---

## Hunter

### Stage 47
A full hunting scenario targeting the player.

- spawns a pursuer
- aggressive AI
- periodic re-aggro / re-targeting
- auto-completes by timer or condition

This is one of the most tense scenarios in the mod.

---

## Show scenarios

### Stage 50 — Fake Hero
Spawns a false “hero” that interferes with the situation.

### Stage 51 — Horror
A horror scenario with visuals and a sense of being hunted (run and don’t stop).

### Stage 52 — Arena
A combat scenario with increased pressure and focus on fighting.

### Stage 53 — Goal-based scenario
A scenario with a goal:
- a weak creature is created
- the player must escort it for a certain time
- success/failure is determined by conditions.

---

## Chaos

### Stage 70 — Zero gravity
Increases jump height and removes fall damage.

### Stage 71 — Weighted chaos
Triggers chaos using configured weights and probabilities.

Both stages are **actions**, not persistent modes.

---

## Inventory

### Stage 80 — Inventory Shuffle
A “rain” of random items.

### Stage 81 — Inventory Punishment
A harsh scenario tied to loss or distortion of resources.

---

## Teleport

### Stage 90–99
A series of teleportation scenarios.

General idea:
- forced relocation of the player
- different algorithms for choosing destination
- suddenness and disorientation

From safer areas to dangerous, unexpected places.

---

## Virus

### Stage 100–103
Long negative states:
- infection
- debuffs
- gradual deterioration
- forced Vampire Lord transformation (does not remove itself; use the “restore state” power from Favorites while in Vampire form)
- forced Werewolf transformation

---

## Weather

### Stage 110–119
Weather and atmospheric pressure manipulation:
- storms
- extreme conditions
- visual impact
- buffs and debuffs

---

## Characteristic

### Stage 120–124
Scenarios related to changing the player:
- size / growth
- speed
- damage

---

## About rewards

Some scenarios are not limited to punishment.

TDL observes **how** the player handles trials:
- how long you endured
- whether you overcame pressure
- whether you reached the objective
- whether you survived where you “shouldn’t”

What happens after that is **not always obvious**.

Sometimes the game responds later. Sometimes differently than expected.  
That’s part of the integration philosophy.

---

*TDL is not just chaos. It is a trial.*

---

# Русская версия
## Описание мода и стадий

> **Навигация по документам**  
> - Описание для Nexus: `1_twitch_dragonborn_legacy_nexus_description.md`  
> - Установка и требования: `2_twitch_dragonborn_legacy_installation_and_requirements.md`  
> - FAQ и известные проблемы: `3_twitch_dragonborn_legacy_faq_and_known_issues.md`  
> - Чего мод НЕ делает: `4_twitch_dragonborn_legacy_what_this_mod_does_not_do.md`  
> - Для стримеров и интерактива: `5_twitch_dragonborn_legacy_for_streamer_and_interactive.md`  
> - Настройка Streamer.bot: `6_twitch_dragonborn_legacy_setting_in_streamer.bot.md`  
> - Описание стадий: `7_twitch_dragonborn_legacy_description_mods_and_stges.md`  
> - Changelog и roadmap: `8_twitch_dragonborn_legacy_changelog_roadmap.md`  

Этот документ описывает стадии/сценарии и их назначение.  
Установка и требования — в `2_twitch_dragonborn_legacy_installation_and_requirements.md`.

---

## Общее описание

**Twitch Dragonborn Legacy (TDL)** — это мод для **Skyrim Special Edition / Anniversary Edition**, построенный как **система команд и сценариев**, а не линейный квест.

TDL предназначен для создания **напряжённого, непредсказуемого и зрелищного геймплея**, где игрок регулярно сталкивается с внешними вмешательствами в ход игры: внезапными событиями, сценариями давления, хаотичными эффектами и испытаниями на выживание.

Ключевая особенность мода — архитектура.

> В TDL стадии квеста используются как **команды**, а не как прогресс.

Каждая стадия — это точка входа в конкретный модуль. Стадии можно вызывать:
- из MCM
- из консоли
- из внешних инструментов
- из стрим-интеграций

Стадии не образуют цепочку и могут вызываться **в любом порядке и многократно**.

---

## Архитектурный принцип стадий

- **Stage ≠ прогресс**
- **Stage = команда**
- Стадии не хранят состояние
- Каждый модуль сам управляет своей логикой

Некоторые стадии запускают мгновенное действие, другие — **асинхронный сценарий**, который живёт во времени и завершается по условиям.

---

## Системные стадии

### Stage 1 — Init / Проверка
Служебная стадия для проверки, что система активна и контроллер доступен.

### Stage 10 — Ping
Используется для проверки связи (MCM, внешний конфигуратор, стрим-команды).

---

## Wrath of God — Божественная кара

### Stage 11 / 12 / 13
Мощные сценарии божественного вмешательства.

- тяжёлые эффекты
- разрушительные события
- высокая степень воздействия

Каждая стадия — отдельный сценарий кары.

---

## Healing и Blessing

### Stage 20 — Healing
Сценарий восстановления и поддержки игрока.

### Stage 30 — Blessing
Временное благословение или усиление.

---

## Summoning — Призывы

### Stage 40 — Случайный призыв
Выбирается случайный объект или существо из общего пула.

### Stage 41–46 — Призыв по списку
Каждая стадия соответствует определённому индексу в списке призывов.

---

## Hunter — Преследователь

### Stage 47
Полноценный сценарий охоты на игрока.

- спавн преследователя
- агрессивный ИИ
- периодическое повторное наведение агрессии
- автоматическое завершение по таймеру или условию

Это один из самых напряжённых сценариев мода.

---

## Show — Необычные сценарии

### Stage 50 — Fake Hero
Появление ложного «героя», вмешивающегося в происходящее.

### Stage 51 — Horror
Хоррор-сценарий с визуальными эффектами и ощущением преследования (беги и не останавливайся).

### Stage 52 — Arena
Боевой сценарий с усиленным давлением и концентрацией на сражении.

### Stage 53 — Goal-based Scenario
Сценарий с целью:
- создаётся слабое существо
- игрок должен сопровождать его определённое время
- успех или провал определяются условиями

---

## Chaos — Хаотические события

### Stage 70 — Нулевая гравитация
Увеличивает высоту прыжка и убирает урон от падения.

### Stage 71 — Взвешенный хаос
Запуск хаоса с учётом настроек и вероятностей.

Обе стадии — **действия**, а не режимы.

---

## Inventory — Вмешательство в инвентарь

### Stage 80 — Inventory Shuffle
Дождь из случайных предметов.

### Stage 81 — Inventory Punishment
Жёсткий сценарий наказания, связанный с потерей или искажением ресурсов.

---

## Teleport — Принудительные перемещения

### Stage 90–99
Серия сценариев телепортации.

Общая идея:
- принудительное перемещение игрока
- разные алгоритмы выбора точки
- внезапность и дезориентация

От безопасных зон до опасных и неожиданных мест.

---

## Virus — Негативные состояния

### Stage 100–103
Длительные негативные эффекты:
- заражение
- дебаффы
- постепенное ухудшение состояния
- принудительное превращение в лорда вампира (состояние не снимается самостоятельно; для выхода используйте способность восстановления состояния из меню «Избранное» в форме вампира)
- принудительное превращение в Оборотня

---

## Weather — Погодные сценарии

### Stage 110–119
Управление погодой и атмосферным давлением:
- штормы
- экстремальные условия
- визуальное воздействие
- баффы и дебаффы

---

## Characteristic — Сценарии характеристик

### Stage 120–124
Сценарии, связанные с изменением игрока:
- рост
- скорость
- урон

---

## О поощрениях

Некоторые сценарии **не ограничиваются наказанием**.

TDL внимательно следит за тем, **как** игрок проходит испытания:
- сколько он выдержал
- справился ли с давлением
- дошёл ли до цели
- выжил ли там, где не должен был

Что именно происходит после этого — **не всегда очевидно**.

Иногда игра отвечает не сразу.  
Иногда — не так, как ожидаешь.

Именно это и является частью философии интеграции.

---

*TDL — это не просто хаос. Это испытание.*
