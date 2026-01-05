TDL_Tools — управление Twitch Dragonborn Legacy (TDL) через Named Pipe
=====================================================================

Назначение
----------
В составе мода есть утилита-«отправлятор», которая позволяет любому софту
(Streamer.bot / SAMMI / LioranBoard / OBS / свои скрипты) запускать эффекты
в игре через запуск внешней команды.

Утилита отправляет строку в named pipe:
  \\.\pipe\TDL_Stream

В составе мода есть утилиты, чтобы удобно отправлять команды и тестировать систему.


Файлы в составе
---------------
Data\TDL_Tools\send_tdl.cmd   — отправка обычных команд вида ACTION|SOURCE
Data\TDL_Tools\send_tdl.ps1   — реализация send_tdl.cmd (PowerShell)
(Эти файлы лежат в Data\TDL_Tools для того, чтобы мод-менеджер устанавливал их автоматически.)

ВАЖНО: запускать нужно send_tdl.cmd, а не .ps1.

Требования
----------
1) Игра запущена и загружено сохранение (мир прогрузился).
2) Установлен мод TDL и SKSE-плагин (TDL_StreamPlugin.dll).
3) Windows 10/11 (named pipe).

Как пользоваться (вручную)
--------------------------
Откройте cmd (Win+R → cmd) и выполните:

  "ПУТЬ_К_ИГРЕ\Data\TDL_Tools\send_tdl.cmd" SYSTEM_PING 2

Пример для стандартной установки Steam (замените путь на свой):
  "F:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data\TDL_Tools\send_tdl.cmd" SYSTEM_BLESSING 2

Где смотреть логи
----------------
1) Лог DLL/SKSE (загрузка плагина, старт pipe, принятые сообщения):
   Documents\My Games\Skyrim Special Edition\SKSE\TDL_StreamPlugin.log

2) Лог Papyrus (принял/отклонил действие, причины):
   Documents\My Games\Skyrim Special Edition\Logs\Script\User\TDL.0.log
   
Как подключить к Streamer.bot / SAMMI / любому софту
----------------------------------------------------
Нужен любой экшен типа "Run program" / "Execute" / "Launch".

Program (Путь к программе):
  <Skyrim>\Data\TDL_Tools\send_tdl.cmd

Обычные команды (основной режим)
--------------------------------
Формат:
  ACTION|SOURCE
  
Где:
	ACTION — идентификатор действия (см. список ниже)
	SOURCE (приоритет источника):
			1 = beats   (выше приоритет)
			2 = points
			3 = vote    (ниже приоритет)

1) Проверка связи (рекомендуется первой)
  SYSTEM_PING 2

2) Хил							7) Хаос
  SYSTEM_HEALING	2			  CHAOS_LOW_G				2
								  CHAOS_BACKFIRE			2
3) Благословение
  SYSTEM_BLESSING	2			8) Инвентарь
								  INVENTORY_SCATTER			2
4) Призывы						  INVENTORY_DROP_ALL		2
  SUMMON_ANY		2			
  SUMMON_SKELETON	2			9) Телепорт
  SUMMON_ANIMAL		2			  TELEPORT_RANDOM_CITY		2
  SUMMON_HUMANOID	2			  TELEPORT_RANDOM_DANGER	2
  SUMMON_UNDEAD		2			  TELEPORT_HIGH_HROTHGAR	2
  SUMMON_STRONG		2			  TELEPORT_WHITERUN			2
  SUMMON_DRAGON		2			  TELEPORT_SOLITUDE			2
								  TELEPORT_WINDHELM			2
5) Охотник						  TELEPORT_RIFTEN			2
  HUNTER_START		2			  TELEPORT_MARKARTH			2
								  TELEPORT_FALKREATH		2
6) Шоу							  TELEPORT_DAWNSTAR			2
  COMEDY_FAKE_HERO	2			
  COMEDY_HORROR		2			10) Вирус
  COMEDY_ARENA		2			  VIRUS_DISEASE				2
  COMEDY_ESCORT		2			  VIRUS_WEREWOLF			2
								  VIRUS_VAMPIRE				2
11) Погода						
  WEATHER_CLEAR		2			12) Гигантизм/скорость
  WEATHER_RAIN		2			  GIGANT_BIG				2
  WEATHER_SNOW		2			  GIGANT_SMALL				2
  WEATHER_STORM		2			  GIGANT_SPEED				2
  WEATHER_FOG		2			  GIGANT_SLOW				2
  WEATHER_RESET		2			  GIGANT_RESET				2

Примеры команд для теста:
  SUMMON_DRAGON|2
  WEATHER_RAIN|1
  TELEPORT_RANDOM_CITY|3


FORCE-команды (ручной режим)
----------------------------
FORCE-команды НЕ доступны чату. Их используют только стример и модераторы вручную.
Чат влияет на игру ТОЛЬКО через:
- Channel Points (монеты)
- Beats
- Голосование (если стример включил)

Есть два типа FORCE:

1) FORCE1 (одиночный форс)
   Формат:
     FORCE1|ACTION

   Разрешённые ACTION:
     SYSTEM_HEALING
     WRATH_11
     WRATH_12
     WRATH_13

   Примеры:
     FORCE1|SYSTEM_HEALING
     FORCE1|WRATH_12

2) FORCE (серия BURST)
   Формат:
     FORCE|ACTION|COUNT
   или (если нужен интервал)
     FORCE|ACTION|COUNT|INTERVAL

   Если поле INTERVAL не указано — используется default 0.85 сек.

   Ограничения интервала (защита от опечаток):
     clamp снизу: 0.75 сек
     clamp сверху: 5.0 сек
     default: 0.85 сек

   Общий лимит серии:
     COUNT максимум 50

   Разрешённые ACTION для серии и дополнительные лимиты:
     - SUMMON_*                 : до 50
     - INVENTORY_SCATTER        : до 10
     - TELEPORT_RANDOM_CITY     : до 5
     - TELEPORT_RANDOM_DANGER   : до 5
     - VIRUS_DISEASE            : до 15

   Примеры:
     FORCE|SUMMON_DRAGON|10
     FORCE|SUMMON_DRAGON|10|1.0
     FORCE|INVENTORY_SCATTER|10
     FORCE|TELEPORT_RANDOM_CITY|5
     FORCE|VIRUS_DISEASE|15|0.9


Важное предупреждение (FORCE / BURST)
-------------------------------------
FORCE/BURST запускаются вручную и сознательно обходят обычные очереди и cooldown’ы.
При большом количестве тяжёлых эффектов (например, массовые саммоны/спавн объектов/
частые телепорты) движок Skyrim может не выдержать нагрузку: возможны сильные просадки FPS,
зависания и краши. Запуская FORCE/BURST, стример принимает этот риск на себя.

STOP_ALL (пауза у бота) НЕ прерывает уже запущенный FORCE/BURST — она останавливает только
дальнейший сбор и отправку событий ботом.


Права и управление (кто что может)
----------------------------------
Стример:
- может использовать все FORCE/ADMIN действия
- имеет эксклюзивную кнопку/команду STOP_ALL (пауза бота)

Модераторы:
- могут использовать все FORCE/ADMIN действия
- НЕ имеют доступа к STOP_ALL

Чат:
- не имеет доступа к FORCE/ADMIN
- влияет на игру только через points/beats/vote (если включено)


STOP_ALL / START_ALL (логика бота)
----------------------------------
STOP_ALL — это пауза планировщика БОТА:
- бот перестаёт собирать и отправлять новые команды в DLL
- то, что уже отправлено в DLL/игру, не отменяется
- Papyrus не трогаем

Возврат в работу:
- либо вручную (START_ALL)
- либо по таймеру (например, авто-старт через 10 минут)


Голосование (максимально простое)
---------------------------------
Стример включает голосование на 2–5 вариантов.
Чат голосует очень просто:
  !1 ... !5   (или просто 1 ... 5)

Правила:
- 1 человек = 1 голос
- суммируем голоса за варианты
- победитель — вариант с наибольшим числом голосов
- при равенстве побеждает вариант, за который был отдан ПОСЛЕДНИЙ голос
- по завершении голосования бот отправляет в DLL одну команду победителя (SOURCE=3)


Как тестировать прямо сейчас
----------------------------
1) Запустить игру и загрузить сохранение.
2) Проверить пинг:
   SYSTEM_PING|2

3) Проверить обычную команду:
   SUMMON_SKELETON|2

Примечание:
send_tdl.cmd предназначен для обычных команд ACTION|SOURCE.
FORCE-строки (FORCE|... и FORCE1|...) обычно отправляются ботом/стрим-софтом “как есть”,
в виде одной строки в pipe.

Типичные проблемы
-----------------
1) Команда не отправляется / ошибка подключения:
   - игра не запущена или сохранение ещё не загружено
   - SKSE-плагин не загрузился (проверьте TDL_StreamPlugin.log)

2) Команда отправляется, но действие не запускается:
   - действие отключено в таблице/настройках
   - действие отклонено из-за приоритета или cooldown (смотрите Papyrus.0.log)

3) Софт не умеет PowerShell:
   - запускайте send_tdl.cmd (он сам вызывает PowerShell корректно)


Подсказка
---------
Для диагностики всегда используйте:
  SYSTEM_PING 2
Если PING работает — значит цепочка связи настроена правильно.