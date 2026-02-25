ScriptName TDL_InGameMenu extends Quest

; === —¬Œ…—“¬¿: ¬≈–’Õ»… ”–Œ¬≈Õ‹ ===
Message Property Page1Msg Auto   ; Force, Chaos, Inventory, Next
Message Property Page2Msg Auto   ; Wrath, Other, Characteristic, Next
Message Property Page3Msg Auto   ; Show, Virus, Teleport, ´ Back to Main

; === FORCE (Ò Ï‡ÒÒÓ‚˚Ï ‚˚ÁÓ‚ÓÏ) ===
Message Property ForcePage1Msg Auto
Message Property ForcePage2Msg Auto
Message Property ForcePage3Msg Auto
Message Property ForcePage4Msg Auto
Message Property ForceCountMsg Auto
Message Property ForceIntervalMsg Auto

; === CHAOS / INVENTORY / WRATH ===
Message Property ChaosMsg Auto
Message Property InventoryMsg Auto
Message Property WrathMsg Auto

; === OTHER ===
Message Property OtherMainMsg Auto
Message Property WeatherPage1Msg Auto
Message Property WeatherPage2Msg Auto
Message Property SummonPage1Msg Auto
Message Property SummonPage2Msg Auto
Message Property SummonPage3Msg Auto

; === CHARACTERISTIC ===
Message Property CharacteristicMsg Auto
Message Property CharacteristicPage2Msg Auto

; === SHOW ===
Message Property ShowPage1Msg Auto
Message Property ShowPage2Msg Auto

; === VIRUS ===
Message Property VirusMsg Auto

; === TELEPORT ===
Message Property TeleportPage1Msg Auto
Message Property TeleportPage2Msg Auto
Message Property TeleportPage3Msg Auto

; ===  ŒÕ“–ŒÀÀ≈– ===
Quest Property MainControllerQuest Auto

; === Œ—ÕŒ¬ÕŒ… ¬’Œƒ ===
Function OpenMenu()
    If !CheckProps()
        Return
    EndIf
    _ShowPage1()
EndFunction

Bool Function CheckProps()
    If Page1Msg == None || Page2Msg == None || Page3Msg == None || \
       ForcePage1Msg == None || ForceCountMsg == None || \
       ChaosMsg == None || InventoryMsg == None || WrathMsg == None || \
       OtherMainMsg == None || WeatherPage1Msg == None || SummonPage1Msg == None || \
       CharacteristicMsg == None || ShowPage1Msg == None || VirusMsg == None || \
       TeleportPage1Msg == None || MainControllerQuest == None
        Debug.Notification("TDL Menu: ÌÂ ‚ÒÂ Ò‚ÓÈÒÚ‚‡ ÔË‚ˇÁ‡Ì˚")
        Return False
    EndIf
    Return True
EndFunction

; === ”–Œ¬≈Õ‹ 1: —“–¿Õ»÷€  ¿“≈√Œ–»… ===

Function _ShowPage1()
    Int btn = Page1Msg.Show()
    If btn == 0
        _ShowForceActions()
    ElseIf btn == 1
        _ShowChaosActions()
    ElseIf btn == 2
        _ShowInventoryActions()
    ElseIf btn == 3
        _ShowPage2()
    EndIf
EndFunction

Function _ShowPage2()
    Int btn = Page2Msg.Show()
    If btn == 0
        _ShowWrathActions()
    ElseIf btn == 1
        _ShowOtherActions()
    ElseIf btn == 2
        _ShowCharacteristicActions()
    ElseIf btn == 3
        _ShowPage3()
    EndIf
EndFunction

Function _ShowPage3()
    Int btn = Page3Msg.Show()
    If btn == 0
        _ShowShowActions()
    ElseIf btn == 1
        _ShowVirusActions()
    ElseIf btn == 2
        _ShowTeleportPage1()
    ElseIf btn == 3
        _ShowPage1()
    EndIf
EndFunction

; === FORCE: Ã¿——Œ¬€… ¬€«Œ¬ ===

Function _ShowForceActions()
    _ShowForcePage1()
EndFunction

Function _ShowForcePage1()
    Int btn = ForcePage1Msg.Show()
    If btn == 0
        _PromptCount(40)
    ElseIf btn == 1
        _PromptCount(41)
    ElseIf btn == 2
        _PromptCount(43)
    ElseIf btn == 3
        _ShowForcePage2()
    EndIf
EndFunction

Function _ShowForcePage2()
    Int btn = ForcePage2Msg.Show()
    If btn == 0
        _PromptCount(44)
    ElseIf btn == 1
        _PromptCount(42)
    ElseIf btn == 2
        _PromptCount(45)
    ElseIf btn == 3
        _ShowForcePage3()
    EndIf
EndFunction

Function _ShowForcePage3()
    Int btn = ForcePage3Msg.Show()
    If btn == 0
        _PromptCount(46)
    ElseIf btn == 1
        _PromptCount(100)
    ElseIf btn == 2
        _PromptCount(80)
    ElseIf btn == 3
        _ShowForcePage4()
    EndIf
EndFunction

Function _ShowForcePage4()
    Int btn = ForcePage4Msg.Show()
    If btn == 0
        _PromptCount(90)
    ElseIf btn == 1
        _PromptCount(91)
    ElseIf btn == 2
        _ShowForcePage3()
    EndIf
EndFunction

Function _PromptCount(Int stage)
    Int btn = ForceCountMsg.Show()
    Int count = 5
    If btn == 0
        count = 5
    ElseIf btn == 1
        count = 10
    ElseIf btn == 2
        count = 30
    ElseIf btn == 3
        count = 50
    EndIf
    _PromptInterval(stage, count)
EndFunction

Function _PromptInterval(Int stage, Int count)
    Int btn = ForceIntervalMsg.Show()
    Float interval = 2.0
    If btn == 0
        interval = 2.0
    ElseIf btn == 1
        interval = 4.0
    ElseIf btn == 2
        interval = 7.0
    ElseIf btn == 3
        interval = 10.0
    EndIf
    _RunMassStage(stage, count, interval)
EndFunction

Function _RunMassStage(Int stage, Int count, Float interval)
    Int i = 0
    While i < count
        MainControllerQuest.SetStage(stage)
        Utility.Wait(interval)
        i += 1
    EndWhile
    _ShowForcePage1()
EndFunction

; === CHAOS / INVENTORY / WRATH ===

Function _ShowChaosActions()
    Int btn = ChaosMsg.Show()
    If btn == 0
        _RunStage(70)
    ElseIf btn == 1
        _RunStage(71)
    ElseIf btn == 3
        _ShowPage1()
    EndIf
EndFunction

Function _ShowInventoryActions()
    Int btn = InventoryMsg.Show()
    If btn == 0
        _RunStage(80)
    ElseIf btn == 1
        _RunStage(81)
    ElseIf btn == 3
        _ShowPage1()
    EndIf
EndFunction

Function _ShowWrathActions()
    Int btn = WrathMsg.Show()
    If btn == 0
        _RunStage(11)
    ElseIf btn == 1
        _RunStage(12)
    ElseIf btn == 2
        _RunStage(13)
    ElseIf btn == 3
        _ShowPage2()
    EndIf
EndFunction

; === OTHER ===

Function _ShowOtherActions()
    Int btn = OtherMainMsg.Show()
    If btn == 0
        _ShowWeatherPage1()
    ElseIf btn == 1
        _ShowSummonPage1()
    ElseIf btn == 2
        _RunStage(20)
    ElseIf btn == 3
        _RunStage(30)
    EndIf
EndFunction

Function _ShowWeatherPage1()
    Int btn = WeatherPage1Msg.Show()
    If btn == 0
        _RunStage(110)
    ElseIf btn == 1
        _RunStage(111)
    ElseIf btn == 2
        _RunStage(112)
    ElseIf btn == 3
        _ShowWeatherPage2()
    EndIf
EndFunction

Function _ShowWeatherPage2()
    Int btn = WeatherPage2Msg.Show()
    If btn == 0
        _RunStage(113)
    ElseIf btn == 1
        _RunStage(114)
    ElseIf btn == 2
        _ShowWeatherPage1()
    EndIf
EndFunction

Function _ShowSummonPage1()
    Int btn = SummonPage1Msg.Show()
    If btn == 0
        _RunStage(40)
    ElseIf btn == 1
        _RunStage(41)
    ElseIf btn == 2
        _RunStage(43)
    ElseIf btn == 3
        _ShowSummonPage2()
    EndIf
EndFunction

Function _ShowSummonPage2()
    Int btn = SummonPage2Msg.Show()
    If btn == 0
        _RunStage(44)
    ElseIf btn == 1
        _RunStage(42)
    ElseIf btn == 2
        _RunStage(45)
    ElseIf btn == 3
        _ShowSummonPage3()
    EndIf
EndFunction

Function _ShowSummonPage3()
    Int btn = SummonPage3Msg.Show()
    If btn == 0
        _RunStage(46)
    ElseIf btn == 1
        _ShowSummonPage2()
    EndIf
EndFunction

; === CHARACTERISTIC ===

Function _ShowCharacteristicActions()
    Int btn = CharacteristicMsg.Show()
    If btn == 0
        _RunStage(120)
    ElseIf btn == 1
        _RunStage(121)
    ElseIf btn == 2
        _RunStage(122)
    ElseIf btn == 3
        _ShowCharacteristicPage2()
    EndIf
EndFunction

Function _ShowCharacteristicPage2()
    Int btn = CharacteristicPage2Msg.Show()
    If btn == 0
        _RunStage(123)
    ElseIf btn == 1
        _RunStage(124)
    ElseIf btn == 3
        _ShowCharacteristicActions()
    EndIf
EndFunction

; === SHOW ===

Function _ShowShowActions()
    _ShowShowPage1()
EndFunction

Function _ShowShowPage1()
    Int btn = ShowPage1Msg.Show()
    If btn == 0
        _RunStage(50)
    ElseIf btn == 1
        _RunStage(51)
    ElseIf btn == 2
        _RunStage(52)
    ElseIf btn == 3
        _ShowShowPage2()
    EndIf
EndFunction

Function _ShowShowPage2()
    Int btn = ShowPage2Msg.Show()
    If btn == 0
        _RunStage(53)
    ElseIf btn == 1
        _RunStage(47)
    ElseIf btn == 2
        _ShowShowPage1()
    EndIf
EndFunction

; === VIRUS ===

Function _ShowVirusActions()
    Int btn = VirusMsg.Show()
    If btn == 0
        _RunStage(100)
    ElseIf btn == 1
        _RunStage(101)
    ElseIf btn == 2
        _RunStage(102)
    ElseIf btn == 3
        _ShowPage3()
    EndIf
EndFunction

; === TELEPORT ===

Function _ShowTeleportPage1()
    Int btn = TeleportPage1Msg.Show()
    If btn == 0
        _RunStage(90)
    ElseIf btn == 1
        _RunStage(91)
    ElseIf btn == 2
        _RunStage(92)
    ElseIf btn == 3
        _ShowTeleportPage2()
    EndIf
EndFunction

Function _ShowTeleportPage2()
    Int btn = TeleportPage2Msg.Show()
    If btn == 0
        _RunStage(93)
    ElseIf btn == 1
        _RunStage(94)
    ElseIf btn == 2
        _RunStage(95)
    ElseIf btn == 3
        _ShowTeleportPage3()
    EndIf
EndFunction

Function _ShowTeleportPage3()
    Int btn = TeleportPage3Msg.Show()
    If btn == 0
        _RunStage(96)
    ElseIf btn == 1
        _RunStage(97)
    ElseIf btn == 2
        _RunStage(98)
    ElseIf btn == 3
        _RunStage(99)
    EndIf
EndFunction

; === «¿œ”—  —“¿ƒ»» ===

Function _RunStage(Int stage)
    MainControllerQuest.SetStage(stage)
EndFunction