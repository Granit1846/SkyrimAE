Scriptname TDL_TestMagicEffect extends ActiveMagicEffect  

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Debug.Notification("TDL: Тестовое заклинание активировано")
    
    ; Получаем основной квест
    Quest mainQuest = Game.GetFormFromFile(0x00000D62, "TwitchDragonbornLegacy.esp") as Quest
    If mainQuest
        (mainQuest as TDL_Main1).TDL_TestHeal()
    EndIf
EndEvent
Actor Property PlayerRef  Auto  
