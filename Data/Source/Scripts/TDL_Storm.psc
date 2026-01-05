Scriptname TDL_Storm extends Quest

; Свойства
Actor Property PlayerRef Auto

Event OnInit()
    PlayerRef = Game.GetPlayer()
    Debug.Notification("[TDL] Стихийный шторм активирован!")
EndEvent

Function TestElementalStorm()
    Debug.Notification("[TDL] Начинается стихийный шторм!")
    
    ; Настройки шторма
    Float stormDuration = 10.0  ; Укороченная длительность для теста
    Float effectInterval = 1.0  ; Чаще взрывы
    Int totalBursts = Math.Floor(stormDuration / effectInterval) as Int
    
    ; Выбираем тип эффекта
    Int stormType = Utility.RandomInt(0, 2)  ; 0-молния, 1-огонь, 2-лед
    Form explosionFX = none
    
    If stormType == 0
        explosionFX = Game.GetFormFromFile(0x000665bb, "Skyrim.esm") ; ExplosionRuneShock01
        Debug.Notification("Молния!")
    ElseIf stormType == 1
        explosionFX = Game.GetFormFromFile(0x0008196b, "Skyrim.esm") ; FireStormExplosion
        Debug.Notification("Огонь!")
    Else
        explosionFX = Game.GetFormFromFile(0x0010a197, "Skyrim.esm") ; crAtronachFrostExplosion
        Debug.Notification("Лёд!")
    EndIf
    
    If !explosionFX
        Debug.Notification("Ошибка: эффект не найден!")
        Return
    EndIf
    
    ; Цикл взрывов
    Int i = 0
    While i < totalBursts
        ; Случайная позиция вокруг игрока
        Float offsetX = Utility.RandomFloat(-300.0, 300.0)
        Float offsetY = Utility.RandomFloat(-300.0, 300.0)
        
        ; Создаем маркер для позиции
        ObjectReference marker = PlayerRef.PlaceAtMe(Game.GetForm(0x0000003B), 1) ; DefaultMarker
        If marker
            marker.MoveTo(PlayerRef, offsetX, offsetY, 50.0)
            
            ; Создаем эффект на маркере
            ObjectReference fx = marker.PlaceAtMe(explosionFX, 1)
            
            ; Удаляем маркер
            marker.Disable()
            marker.Delete()
            
            ; Урон игроку
            Float damage = Utility.RandomFloat(5.0, 15.0)
            PlayerRef.DamageAV("Health", damage)
            
            ; Легкая тряска
            If i % 2 == 0
                Game.ShakeCamera(PlayerRef, 0.2, 0.5)
            EndIf
        EndIf
        
        Utility.Wait(effectInterval)
        i += 1
    EndWhile
    
    Debug.Notification("[TDL] Шторм завершен!")
EndFunction

; Упрощенный шторм с одним типом
Function SimpleStorm(Int stormType)
    ; stormType: 0=молния, 1=огонь, 2=лед
    Form explosionFX = none
    String stormName = "Шторм"
    
    If stormType == 0
        explosionFX = Game.GetFormFromFile(0x000665bb, "Skyrim.esm")
        stormName = "Молния"
    ElseIf stormType == 1
        explosionFX = Game.GetFormFromFile(0x0008196b, "Skyrim.esm")
        stormName = "Огонь"
    ElseIf stormType == 2
        explosionFX = Game.GetFormFromFile(0x0010a197, "Skyrim.esm")
        stormName = "Лёд"
    EndIf
    
    If explosionFX
        Debug.Notification(stormName + " начинает бушевать!")
        
        ; Создаем несколько взрывов
        Int i = 0
        While i < 5
            ObjectReference fx = PlayerRef.PlaceAtMe(explosionFX, 1)
            If fx
                fx.MoveTo(PlayerRef, Utility.RandomFloat(-200, 200), Utility.RandomFloat(-200, 200), 0)
                Game.ShakeCamera(PlayerRef, 0.3, 0.5)
                PlayerRef.DamageAV("Health", Utility.RandomFloat(8, 20))
            EndIf
            Utility.Wait(0.5)
            i += 1
        EndWhile
        
        Debug.Notification(stormName + " утихает...")
    EndIf
EndFunction

Event OnStageSet(Int aiStage)
    If aiStage == 10
        TestElementalStorm()
        SetStage(0)
    EndIf
EndEvent