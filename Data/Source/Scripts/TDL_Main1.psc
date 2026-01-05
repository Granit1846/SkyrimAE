Scriptname TDL_Main1 extends Quest

; Свойства
Actor Property PlayerRef Auto
GlobalVariable Property TDL_Enabled Auto
GlobalVariable Property TDL_UpdateInterval Auto
GlobalVariable Property TDL_DebugMode Auto

; Внутренние переменные
Int TestCounter = 0
Bool IsInitialized = false
Float UpdateDelay = 15.0  ; Фиксированная задержка 15 секунд

; === ИНИЦИАЛИЗАЦИЯ ===
Event OnInit()
    Debug.Notification("[TDL] Twitch Dragonborn Legacy загружен!")
    InitializeSystem()
EndEvent

Function InitializeSystem()
    If !IsInitialized
        PlayerRef = Game.GetPlayer()
        IsInitialized = true

        Debug.Notification("[TDL] Задержка цикла: " + UpdateDelay + " секунд")

        ; Запускаем тестовый цикл
        StartTestCycle()
    EndIf
EndFunction

; === ТЕСТОВЫЙ ЦИКЛ ===
Function StartTestCycle()
    If TDL_Enabled.GetValue() == 1.0
        Debug.Notification("[TDL] Запуск тестового цикла!")
        Debug.Notification("[TDL] Задержка: " + UpdateDelay + " сек")
        TestCounter = 0
        RegisterForSingleUpdate(2.0)
    EndIf
EndFunction

Event OnUpdate()
    If TDL_Enabled.GetValue() == 1.0
        TestCounter += 1

        If TestCounter == 1
            Debug.Notification("[TDL] Цикл 1: Исцеление")
            TestHealing()
            RegisterForSingleUpdate(UpdateDelay)
        ElseIf TestCounter == 2
            Debug.Notification("[TDL] Цикл 2: Стихийный шторм")
            TestElementalStorm()
            RegisterForSingleUpdate(UpdateDelay)
        ElseIf TestCounter == 3
            Debug.Notification("[TDL] Цикл 3: Существа")
            TestCreatures()
            RegisterForSingleUpdate(UpdateDelay)
        ElseIf TestCounter == 4
            Debug.Notification("[TDL] Цикл 4: Божественные благословения и знаки")
            TestDivineBlessings()
            TestCounter = 0
            RegisterForSingleUpdate(UpdateDelay)
        EndIf
    EndIf
EndEvent

; === ИСПРАВЛЕННЫЕ ЭФФЕКТЫ ===

; 1. ИСЦЕЛЕНИЕ с GrandHealing (000B62EE)
Function TestHealing()
    ; Восстановление
    Float healthBefore = PlayerRef.GetActorValue("Health")
    Float magickaBefore = PlayerRef.GetActorValue("Magicka")
    Float staminaBefore = PlayerRef.GetActorValue("Stamina")

    ; Используем GrandHealing заклинание
    Spell grandHeal = Game.GetFormFromFile(0x000B62EE, "Skyrim.esm") as Spell ; GrandHealing
    If grandHeal
        Debug.Notification("Применяю Grand Healing!")
        grandHeal.Cast(PlayerRef, PlayerRef)
    Else
        ; Фолбэк: стандартное исцеление
        Debug.Notification("Grand Heal не найден, использую фолбэк")
        PlayerRef.RestoreActorValue("Health", 500)
        PlayerRef.RestoreActorValue("Magicka", 500)
        PlayerRef.RestoreActorValue("Stamina", 500)

        ; Визуальный эффект
        Form healFX = Game.GetFormFromFile(0x0001C9E3, "Skyrim.esm") ; ExplosionFire50
        If healFX
            ObjectReference fx = PlayerRef.PlaceAtMe(healFX, 1)
            Utility.Wait(0.3)
            If fx
                fx.Disable()
                fx.Delete()
            EndIf
        EndIf
    EndIf

    ; Звук исцеления
    Sound healSound = Game.GetFormFromFile(0x0003C6D6, "Skyrim.esm") as Sound ; MAGHeal
    If healSound
        healSound.Play(PlayerRef)
    EndIf

    Debug.Notification("Исцеление применено!")

    ; Отладка
    If TDL_DebugMode.GetValue() == 1.0
        Float healthAfter = PlayerRef.GetActorValue("Health")
        Float magickaAfter = PlayerRef.GetActorValue("Magicka")
        Float staminaAfter = PlayerRef.GetActorValue("Stamina")
        Debug.Notification("Здоровье: " + healthBefore + " -> " + healthAfter)
        Debug.Notification("Магия: " + magickaBefore + " -> " + magickaAfter)
        Debug.Notification("Выносливость: " + staminaBefore + " -> " + staminaAfter)
    EndIf
EndFunction

; 2. СТИХИЙНЫЙ ШТОРМ - с уроном к мане/выносливости и поджиганием (ИСПРАВЛЕННАЯ ВЕРСИЯ)
Function TestElementalStorm()
    Debug.Notification("[TDL] Начинается стихийный шторм!")
    
    ; Расширенный массив эффектов
    Int[] effectIDs = new Int[11]
    String[] effectNames = new String[11]
    Float[] minDamages = new Float[11]
    Float[] maxDamages = new Float[11]
    Int[] effectTypes = new Int[11]
    
    ; Молния - урон мане
    effectIDs[0] = 0x000665bb
    effectNames[0] = "Молния"
    minDamages[0] = 10.0
    maxDamages[0] = 25.0
    effectTypes[0] = 0
    
    effectIDs[1] = 0x00073326
    effectNames[1] = "Электрический разряд"
    minDamages[1] = 10.0
    maxDamages[1] = 22.0
    effectTypes[1] = 0
    
    ; Огонь (средний)
    effectIDs[2] = 0x0010f213
    effectNames[2] = "Огненный шар"
    minDamages[2] = 12.0
    maxDamages[2] = 25.0
    effectTypes[2] = 1
    
    effectIDs[3] = 0x0010815e
    effectNames[3] = "Магический огонь"
    minDamages[3] = 10.0
    maxDamages[3] = 20.0
    effectTypes[3] = 1
    
    effectIDs[4] = 0x000e7721
    effectNames[4] = "Драконий огонь"
    minDamages[4] = 15.0
    maxDamages[4] = 30.0
    effectTypes[4] = 1
    
    ; Огонь (сильный)
    effectIDs[5] = 0x00097ee4
    effectNames[5] = "Взрыв пламени"
    minDamages[5] = 18.0
    maxDamages[5] = 35.0
    effectTypes[5] = 1
    
    effectIDs[6] = 0x0008196b
    effectNames[6] = "Огненный шторм"
    minDamages[6] = 20.0
    maxDamages[6] = 40.0
    effectTypes[6] = 1
    
    ; Лед - урон выносливости
    effectIDs[7] = 0x0010a197
    effectNames[7] = "Ледяной взрыв"
    minDamages[7] = 8.0
    maxDamages[7] = 16.0
    effectTypes[7] = 2
    
    effectIDs[8] = 0x000ed39b
    effectNames[8] = "Морозный туман"
    minDamages[8] = 6.0
    maxDamages[8] = 14.0
    effectTypes[8] = 2
    
    effectIDs[9] = 0x00078c12
    effectNames[9] = "Ледяная буря"
    minDamages[9] = 12.0
    maxDamages[9] = 28.0
    effectTypes[9] = 2
    
    ; Поджигание
    effectIDs[10] = 0x0008196b
    effectNames[10] = "ПОДЖИГАНИЕ"
    minDamages[10] = 25.0
    maxDamages[10] = 45.0
    effectTypes[10] = 3
    
    ; Выбираем случайный эффект
    Int randomIndex = Utility.RandomInt(0, effectIDs.Length - 1)
    Int selectedID = effectIDs[randomIndex]
    String effectName = effectNames[randomIndex]
    Float minDamage = minDamages[randomIndex]
    Float maxDamage = maxDamages[randomIndex]
    Int effectType = effectTypes[randomIndex]
    
    Debug.Notification("[TDL] " + effectName + " на 15 секунд!")
    
    Float healthBefore = PlayerRef.GetActorValue("Health")
    Float magickaBefore = PlayerRef.GetActorValue("Magicka")
    Float staminaBefore = PlayerRef.GetActorValue("Stamina")
    
    Float stormDuration = 15.0
    Float effectInterval = 1.5
    Int totalBursts = Math.Floor(stormDuration / effectInterval) as Int
    
    Form explosionForm = Game.GetFormFromFile(selectedID, "Skyrim.esm")
    If !explosionForm
        Debug.Notification("[TDL] Ошибка: форма эффекта не найдена!")
        Return
    EndIf
    
    Bool isOnFire = false
    If effectType == 3
        isOnFire = true
        Debug.Notification("[TDL] ВЫ ПОДЖИГАЕТЕСЬ! Бегите к воде!")
        
        Spell flameSpell = Game.GetFormFromFile(0x00012FCD, "Skyrim.esm") as Spell
        If flameSpell
            PlayerRef.AddSpell(flameSpell, false)
        EndIf
    EndIf
    
    Int i = 0
    While i < totalBursts && TDL_Enabled.GetValue() == 1.0
        Float playerX = PlayerRef.GetPositionX()
        Float playerY = PlayerRef.GetPositionY()
        Float playerZ = PlayerRef.GetPositionZ()
        
        Float offX = playerX + Utility.RandomFloat(-600.0, 600.0)
        Float offY = playerY + Utility.RandomFloat(-600.0, 600.0)
        Float offZ = playerZ + Utility.RandomFloat(0.0, 300.0)
        
        ObjectReference tempMarker = PlayerRef.PlaceAtMe(Game.GetForm(0x0000003B), 1)
        If tempMarker
            tempMarker.SetPosition(offX, offY, offZ)
            ObjectReference fx = tempMarker.PlaceAtMe(explosionForm, 1, false, false)
            tempMarker.Disable()
            tempMarker.Delete()
            
            If fx
                RegisterForSingleUpdateGameTime(0.0007)
            EndIf
        EndIf
        
        If i % 3 == 0
            Game.ShakeCamera(PlayerRef, 0.3, 0.5)
        EndIf
        
        Float damage = Utility.RandomFloat(minDamage, maxDamage)
        PlayerRef.DamageAV("Health", damage)
        
        If effectType == 0
            Float magickaDamage = damage * 0.7
            PlayerRef.DamageAV("Magicka", magickaDamage)
            If i % 2 == 0
                Debug.Notification("Мана повреждена: -" + Math.Floor(magickaDamage))
            EndIf
            
        ElseIf effectType == 2
            Float staminaDamage = damage * 0.6
            PlayerRef.DamageAV("Stamina", staminaDamage)
            If i % 2 == 0
                Debug.Notification("Выносливость повреждена: -" + Math.Floor(staminaDamage))
            EndIf
            
        ElseIf effectType == 3
            If i % 3 == 0
                Float fireDamage = damage * 0.4
                PlayerRef.DamageAV("Health", fireDamage)
                Debug.Notification("ГОРИТЕ! Доп. урон: -" + Math.Floor(fireDamage))
            EndIf
        EndIf
        
        If damage > 15
            Game.ShakeController(0.2, 0.2, 0.3)
        EndIf
        
        Utility.Wait(effectInterval)
        i += 1
    EndWhile
    
    If isOnFire
        Utility.Wait(5.0)
        Spell flameSpell = Game.GetFormFromFile(0x00012FCD, "Skyrim.esm") as Spell
        If flameSpell && PlayerRef.HasSpell(flameSpell)
            PlayerRef.RemoveSpell(flameSpell)
        EndIf
        Debug.Notification("[TDL] Огонь потушен!")
    EndIf
    
    Float healthAfter = PlayerRef.GetActorValue("Health")
    Float magickaAfter = PlayerRef.GetActorValue("Magicka")
    Float staminaAfter = PlayerRef.GetActorValue("Stamina")
    
    Debug.Notification("[TDL] " + effectName + " завершен!")
    
    If TDL_DebugMode.GetValue() == 1.0
        Debug.Notification("=== РЕЗУЛЬТАТЫ ШТОРМА ===")
        
        ; Исправленные строки - без переноса
        String healthMessage1 = "Здоровье: " + Math.Floor(healthBefore) + " -> " + Math.Floor(healthAfter)
        String healthMessage2 = " (изменение: " + Math.Floor(healthAfter - healthBefore) + ")"
        Debug.Notification(healthMessage1 + healthMessage2)
        
        If effectType == 0
            String magickaMessage1 = "Мана: " + Math.Floor(magickaBefore) + " -> " + Math.Floor(magickaAfter)
            String magickaMessage2 = " (изменение: " + Math.Floor(magickaAfter - magickaBefore) + ")"
            Debug.Notification(magickaMessage1 + magickaMessage2)
        ElseIf effectType == 2
            String staminaMessage1 = "Выносливость: " + Math.Floor(staminaBefore) + " -> " + Math.Floor(staminaAfter)
            String staminaMessage2 = " (изменение: " + Math.Floor(staminaAfter - staminaBefore) + ")"
            Debug.Notification(staminaMessage1 + staminaMessage2)
        EndIf
    EndIf
EndFunction

; 3. ПРИЗЫВ СУЩЕСТВ - с расстоянием 500
Function TestCreatures()
    ; Массив проверенных ID
    Int[] creatureIDs = new Int[6]

    creatureIDs[0] = 0x00023ABE  ; Волк (Wolf)
    creatureIDs[1] = 0x00023A8A  ; Медведь (Bear)
    creatureIDs[2] = 0x00023AB5  ; Саблезуб (Sabre Cat)
    creatureIDs[3] = 0x000A5600  ; Сетчатый червь (Chaurus)
    creatureIDs[4] = 0x00023AAE  ; Великан (Giant)
    creatureIDs[5] = 0x0003DE92  ; Бандит (Bandit)

    ; Выбираем случайное существо
    Int randomIndex = Utility.RandomInt(0, creatureIDs.Length - 1)
    Int selectedID = creatureIDs[randomIndex]

    ; Определяем тип существа для сообщения
    String creatureName = "Существо"
    If selectedID == 0x00023ABE
        creatureName = "Волк"
    ElseIf selectedID == 0x00023A8A
        creatureName = "Медведь"
    ElseIf selectedID == 0x00023AB5
        creatureName = "Саблезуб"
    ElseIf selectedID == 0x000A5600
        creatureName = "Сетчатый червь"
    ElseIf selectedID == 0x00023AAE
        creatureName = "Великан"
    ElseIf selectedID == 0x0003DE92
        creatureName = "Бандит"
    EndIf

    Debug.Notification("Призываю " + creatureName + "...")

    ; Пытаемся получить форму
    Form creatureForm = Game.GetFormFromFile(selectedID, "Skyrim.esm")

    If !creatureForm
        ; Если не получилось, пробуем через консоль
        Debug.Notification("Форма не найдена, использую консоль...")
        String hexID = ""
        If selectedID == 0x00023ABE
            hexID = "00023ABE"
        ElseIf selectedID == 0x00023A8A
            hexID = "00023A8A"
        ElseIf selectedID == 0x00023AB5
            hexID = "00023AB5"
        ElseIf selectedID == 0x000A5600
            hexID = "000A5600"
        ElseIf selectedID == 0x00023AAE
            hexID = "00023AAE"
        ElseIf selectedID == 0x0003DE92
            hexID = "0003DE92"
        EndIf

        ConsoleUtil.ExecuteCommand("player.placeatme " + hexID + " 1")
        Debug.Notification(creatureName + " призван через консоль!")
        Return
    EndIf

    ; Создаем существо
    Actor creature = PlayerRef.PlaceAtMe(creatureForm, 1) as Actor

    If creature
        ; Перемещаем на 500 единиц вперед
        Float angleZ = PlayerRef.GetAngleZ()
        Float offsetX = 500 * Math.Sin(angleZ)  ; 500 единиц
        Float offsetY = 500 * Math.Cos(angleZ)  ; 500 единиц

        creature.MoveTo(PlayerRef, offsetX, offsetY, 0)

        ; Если это не великан, начинаем бой
        If selectedID != 0x00023AAE  ; Если не великан
            creature.StartCombat(PlayerRef)
        Else
            ; Великан атакует только если подойти близко
            creature.SetAlert(true)
            Debug.Notification("Великан появился! Будьте осторожны!")
        EndIf

        ; Визуальный эффект призыва
        Form summonFX = Game.GetFormFromFile(0x0001C9E3, "Skyrim.esm") ; ExplosionFire50
        If summonFX
            ObjectReference fx = creature.PlaceAtMe(summonFX, 1)
            Utility.Wait(0.3)
            If fx
                fx.Disable()
                fx.Delete()
            EndIf
        EndIf

        Debug.Notification(creatureName + " успешно призван!")

        ; Удаляем через 60 секунд (только если это не великан)
        If selectedID != 0x00023AAE
            RegisterForSingleUpdateGameTime(0.04) ; ~1 час игрового времени
        EndIf
    Else
        Debug.Notification("Не удалось создать " + creatureName)
    EndIf
EndFunction

; 4. БОЖЕСТВЕННЫЕ БЛАГОСЛОВЕНИЯ И ЗНАКИ (БЕЗ УДАЛЕНИЯ ПРЕДЫДУЩИХ)
Function TestDivineBlessings()
    ; Массив благословений и знаков
    Int[] effects = new Int[18]

    ; Благословения богов
    effects[0] = 0x000FB988  ; AltarAkatoshSpell - Благословение Акатоша
    effects[1] = 0x000FB994  ; AltarArkaySpell - Благословение Аркея
    effects[2] = 0x000FB995  ; AltarDibellaSpell - Благословение Дибеллы
    effects[3] = 0x000FB996  ; AltarJulianosSpell - Благословение Джулиана
    effects[4] = 0x000FB997  ; AltarKynarethSpell - Благословение Кинарет
    effects[5] = 0x000FB998  ; AltarMaraSpell - Благословение Мары
    effects[6] = 0x000FB999  ; AltarStendarrSpell - Благословение Стендара
    effects[7] = 0x000FB99A  ; AltarTalosSpell - Благословение Талоса
    effects[8] = 0x000FB99B  ; AltarZenitharSpell - Благословение Зенитара

    ; Знаки созвездий (doom...Ability)
    effects[9]  = 0x000E5F4E ; doomApprenticeAbility - Знак Ученика
    effects[10] = 0x000E5F47 ; doomMageAbility      - Знак Мага
    effects[11] = 0x000E5F5A ; doomLoverAbility     - Знак Любовника
    effects[12] = 0x000E5F58 ; doomLordAbility      - Знак Лорда
    effects[13] = 0x000E5F54 ; doomLadyAbility      - Знак Леди
    effects[14] = 0x000E5F45 ; doomThiefAbility     - Знак Вора
    effects[15] = 0x000E5F4C ; doomWarriorAbility   - Знак Воина
    effects[16] = 0x000E5F51 ; doomAtronachAbility  - Знак Атронаха
    effects[17] = 0x000E5F5E ; doomSteedAbility     - Знак Коня

    ; Выбираем случайный эффект
    Int randomIndex = Utility.RandomInt(0, effects.Length - 1)
    Int selectedID = effects[randomIndex]

    String effectName = "Благословение"
    Bool isDivine = true

    If selectedID == 0x000FB988
        effectName = "Благословение Акатоша"
    ElseIf selectedID == 0x000FB994
        effectName = "Благословение Аркея"
    ElseIf selectedID == 0x000FB995
        effectName = "Благословение Дибеллы"
    ElseIf selectedID == 0x000FB996
        effectName = "Благословение Джулиана"
    ElseIf selectedID == 0x000FB997
        effectName = "Благословение Кинарет"
    ElseIf selectedID == 0x000FB998
        effectName = "Благословение Мары"
    ElseIf selectedID == 0x000FB999
        effectName = "Благословение Стендара"
    ElseIf selectedID == 0x000FB99A
        effectName = "Благословение Талоса"
    ElseIf selectedID == 0x000FB99B
        effectName = "Благословение Зенитара"
    Else
        isDivine = false
        If selectedID == 0x000E5F4E
            effectName = "Знак Ученика"
        ElseIf selectedID == 0x000E5F47
            effectName = "Знак Мага"
        ElseIf selectedID == 0x000E5F5A
            effectName = "Знак Любовника"
        ElseIf selectedID == 0x000E5F58
            effectName = "Знак Лорда"
        ElseIf selectedID == 0x000E5F54
            effectName = "Знак Леди"
        ElseIf selectedID == 0x000E5F45
            effectName = "Знак Вора"
        ElseIf selectedID == 0x000E5F4C
            effectName = "Знак Воина"
        ElseIf selectedID == 0x000E5F51
            effectName = "Знак Атронаха"
        ElseIf selectedID == 0x000E5F5E
            effectName = "Знак Коня"
        EndIf
    EndIf

    Debug.Notification("[TDL] " + effectName + "!")

    ; Применяем благословение или знак
    Spell effectSpell = Game.GetFormFromFile(selectedID, "Skyrim.esm") as Spell

    If effectSpell
        If isDivine
            ; Благословения - просто кастуем на игрока
            effectSpell.Cast(PlayerRef, PlayerRef)
            Debug.Notification(effectName + " применено!")
        Else
            ; Знаки - добавляем как постоянную способность
            If !PlayerRef.HasSpell(effectSpell)
                PlayerRef.AddSpell(effectSpell, false)
                Debug.Notification(effectName + " получен!")
            Else
                Debug.Notification("У вас уже есть " + effectName)
            EndIf
        EndIf
    Else
        Debug.Notification("Ошибка: эффект не найден!")
    EndIf

    ; Визуальный эффект
    Form blessingFX = Game.GetFormFromFile(0x0001C9E3, "Skyrim.esm") ; ExplosionFire50
    If blessingFX
        ObjectReference fx = PlayerRef.PlaceAtMe(blessingFX, 1)
        Utility.Wait(0.3)
        If fx
            fx.Disable()
            fx.Delete()
        EndIf
    EndIf

    ; Звуковой эффект
    Sound blessingSound = Game.GetFormFromFile(0x0003C6D6, "Skyrim.esm") as Sound ; MAGHeal
    If blessingSound
        blessingSound.Play(PlayerRef)
    EndIf

    Debug.Notification("[TDL] " + effectName + " завершено!")
EndFunction

; === КОНСОЛЬНЫЕ КОМАНДЫ ===

Function TDL_TestHeal()
    Debug.Notification("TDL: Тест исцеления")
    TestHealing()
EndFunction

Function TDL_TestStorm()
    Debug.Notification("TDL: Тест стихийного шторма")
    TestElementalStorm()
EndFunction

Function TDL_TestCreatures()
    Debug.Notification("TDL: Тест существ")
    TestCreatures()
EndFunction

Function TDL_TestBlessings()
    Debug.Notification("TDL: Тест благословений и знаков")
    TestDivineBlessings()
EndFunction

Function TDL_Enable()
    TDL_Enabled.SetValue(1)
    StartTestCycle()
    Debug.Notification("TDL: Мод включен")
EndFunction

Function TDL_Disable()
    TDL_Enabled.SetValue(0)
    UnregisterForUpdate()
    Debug.Notification("TDL: Мод выключен")
EndFunction

Function TDL_SetDelay(Int seconds)
    If seconds > 0
        UpdateDelay = seconds as Float
        Debug.Notification("TDL: Задержка установлена: " + seconds + " сек")
    Else
        Debug.Notification("TDL: Ошибка! Введите положительное число")
    EndIf
EndFunction

Function TDL_GetDelay()
    Debug.Notification("TDL: Текущая задержка: " + UpdateDelay + " сек")
EndFunction