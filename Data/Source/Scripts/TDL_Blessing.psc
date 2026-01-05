Scriptname TDL_Blessings extends Quest

; Свойства
Actor Property PlayerRef Auto

Event OnInit()
    PlayerRef = Game.GetPlayer()
    Debug.Notification("[TDL] Благословения и знаки активированы!")
EndEvent

Function TestDivineBlessings()
    ; Включаем режим бога (TGM) на 30 секунд
    ConsoleUtil.ExecuteCommand("tgm")
    Debug.Notification("[TDL] Режим бога включен на 30 секунд")

    ; Массив всех эффектов
    Int[] effects = new Int[18]
    String[] effectNames = new String[18]
    Bool[] isDivineArray = new Bool[18]
    
    ; Благословения богов
    effects[0] = 0x000FB988
    effectNames[0] = "Благословение Акатоша"
    isDivineArray[0] = true
    
    effects[1] = 0x000FB994
    effectNames[1] = "Благословение Аркея"
    isDivineArray[1] = true
    
    effects[2] = 0x000FB995
    effectNames[2] = "Благословение Дибеллы"
    isDivineArray[2] = true
    
    effects[3] = 0x000FB996
    effectNames[3] = "Благословение Джулиана"
    isDivineArray[3] = true
    
    effects[4] = 0x000FB997
    effectNames[4] = "Благословение Кинарет"
    isDivineArray[4] = true
    
    effects[5] = 0x000FB998
    effectNames[5] = "Благословение Мары"
    isDivineArray[5] = true
    
    effects[6] = 0x000FB999
    effectNames[6] = "Благословение Стендара"
    isDivineArray[6] = true
    
    effects[7] = 0x000FB99A
    effectNames[7] = "Благословение Талоса"
    isDivineArray[7] = true
    
    effects[8] = 0x000FB99B
    effectNames[8] = "Благословение Зенитара"
    isDivineArray[8] = true
    
    ; Знаки созвездий
    effects[9] = 0x000E5F4E
    effectNames[9] = "Знак Ученика"
    isDivineArray[9] = false
    
    effects[10] = 0x000E5F47
    effectNames[10] = "Знак Мага"
    isDivineArray[10] = false
    
    effects[11] = 0x000E5F5A
    effectNames[11] = "Знак Любовника"
    isDivineArray[11] = false
    
    effects[12] = 0x000E5F58
    effectNames[12] = "Знак Лорда"
    isDivineArray[12] = false
    
    effects[13] = 0x000E5F54
    effectNames[13] = "Знак Леди"
    isDivineArray[13] = false
    
    effects[14] = 0x000E5F45
    effectNames[14] = "Знак Вора"
    isDivineArray[14] = false
    
    effects[15] = 0x000E5F4C
    effectNames[15] = "Знак Воина"
    isDivineArray[15] = false
    
    effects[16] = 0x000E5F51
    effectNames[16] = "Знак Атронаха"
    isDivineArray[16] = false
    
    effects[17] = 0x000E5F5E
    effectNames[17] = "Знак Коня"
    isDivineArray[17] = false
    
    ; Выбираем случайный эффект
    Int randomIndex = Utility.RandomInt(0, effects.Length - 1)
    Int selectedID = effects[randomIndex]
    String effectName = effectNames[randomIndex]
    Bool isDivine = isDivineArray[randomIndex]
    
    Debug.Notification("[TDL] " + effectName + "!")
    
    ; Получаем заклинание
    Spell effectSpell = Game.GetFormFromFile(selectedID, "Skyrim.esm") as Spell
    
    If !effectSpell
        Debug.Notification("Ошибка: заклинание не найдено!")
        
        ; Выключаем TGM, чтобы не залип, если что-то пошло не так
        Utility.Wait(30.0)
        ConsoleUtil.ExecuteCommand("tgm")
        Debug.Notification("[TDL] Режим бога выключен")
        Return
    EndIf
    
    ; Применяем эффект
    If isDivine
        effectSpell.Cast(PlayerRef, PlayerRef)
        Debug.Notification(effectName + " применено!")
    Else
        If !PlayerRef.HasSpell(effectSpell)
            PlayerRef.AddSpell(effectSpell, false)
            Debug.Notification(effectName + " получен!")
        Else
            Debug.Notification("У вас уже есть " + effectName)
        EndIf
    EndIf
    
    ; Визуальный эффект
    Form blessingFX = Game.GetFormFromFile(0x0001C9E3, "Skyrim.esm")
    If blessingFX
        ObjectReference fx = PlayerRef.PlaceAtMe(blessingFX, 1)
        Utility.Wait(0.3)
        If fx
            fx.Disable()
            fx.Delete()
        EndIf
    EndIf
    
    ; Звуковой эффект
    Sound blessingSound = Game.GetFormFromFile(0x0003C6D6, "Skyrim.esm") as Sound
    If blessingSound
        blessingSound.Play(PlayerRef)
    EndIf
    
    Debug.Notification("[TDL] " + effectName + " завершено!")
    
    ; Ждём 30 секунд и выключаем режим бога
    Utility.Wait(30.0)
    ConsoleUtil.ExecuteCommand("tgm")
    Debug.Notification("[TDL] Режим бога выключен")
EndFunction

; Функция для применения конкретного благословения
Function ApplyBlessing(Int blessingID)
    Spell blessingSpell = Game.GetFormFromFile(blessingID, "Skyrim.esm") as Spell
    If blessingSpell
        blessingSpell.Cast(PlayerRef, PlayerRef)
        Debug.Notification("Благословение применено!")
    EndIf
EndFunction

; Функция для добавления конкретного знака
Function AddSign(Int signID)
    Spell signSpell = Game.GetFormFromFile(signID, "Skyrim.esm") as Spell
    If signSpell && !PlayerRef.HasSpell(signSpell)
        PlayerRef.AddSpell(signSpell, false)
        Debug.Notification("Знак добавлен!")
    EndIf
EndFunction

Event OnStageSet(Int aiStage)
    If aiStage == 10
        TestDivineBlessings()
        SetStage(0)
    EndIf
EndEvent