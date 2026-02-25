ScriptName TDL_MenuTrigger extends ActiveMagicEffect

Quest Property MainControllerQuest Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If MainControllerQuest != None
        MainControllerQuest.SetStage(999)
    EndIf
EndEvent