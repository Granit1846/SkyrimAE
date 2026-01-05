ScriptName TDL_Chaos_AliasScript extends ReferenceAlias

; === СВОЙСТВА ===
Quest Property TDL_ControllerQuest Auto
Actor Property PlayerAlias Auto

; === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
Function ShowMsg(String msgText)  ; Изменил имя параметра
    Debug.Notification(msgText)
EndFunction

; === ИСПРАВЛЕННАЯ ФУНКЦИЯ GetPlayer ===
Actor Function GetPlayer()
    Actor player = Game.GetPlayer()
    If player == None
        ShowMsg("Игрок не найден!")
    EndIf
    Return player
EndFunction

; === ЭФФЕКТ НИЗКОЙ ГРАВИТАЦИИ ===
Function ApplyLowG()
    Actor player = GetPlayer()
    If player == None
        Return
    EndIf
    
    Spell lowGSpell = Game.GetFormFromFile(0x0002F8B2, "Skyrim.esm") as Spell
    If lowGSpell != None
        player.AddSpell(lowGSpell, false)
        ShowMsg("Эффект низкой гравитации применен!")
    EndIf
EndFunction

; === ОБРАТНЫЙ ЭФФЕКТ КРИКА ===
Function ApplyShoutBackfire()
    Actor player = GetPlayer()
    If player == None
        Return
    EndIf

    Spell backfireSpell = Game.GetFormFromFile(0x0004DEEA, "Skyrim.esm") as Spell
    If backfireSpell != None
        player.AddSpell(backfireSpell, false)
        ShowMsg("Обратный эффект крика применен!")
    EndIf
EndFunction