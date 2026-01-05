Scriptname TDL_Chaos_PlayerAlias extends ReferenceAlias

Keyword Property MagicShout Auto
Quest Property ChaosQuest Auto  ; Привязываем к квесту TDL_MainControllerQuest

Event OnInit()
    ; Проверяем, что квест правильно привязан
    if ChaosQuest == None
        Debug.Notification("ChaosQuest not set!")
        return
    endif

    ; Проверяем, активен ли эффект обратного удара от криков
    if ChaosQuest.IsShoutBackfireEnabled()
        Debug.Notification("Shout backfire is enabled!")
    endif
EndEvent

Event OnSpellCast(Form akSpell)
    ; Если квест не привязан, ничего не делаем
    if ChaosQuest == None
        return
    endif

    ; Если обратный эффект не активирован, ничего не делаем
    if !ChaosQuest.IsShoutBackfireEnabled()
        return
    endif

    ; Если заклинание не крик, ничего не делаем
    if akSpell == None || MagicShout == None
        return
    endif

    ; Проверяем, является ли заклинание криком
    Spell s = akSpell as Spell
    if s == None
        return
    endif

    if !s.HasKeyword(MagicShout)
        return
    endif

    ; Получаем шанс срабатывания обратного удара от крика
    Float chance = ChaosQuest.GetShoutBackfireChance()
    if Utility.RandomFloat(0.0, 100.0) <= chance
        ChaosQuest.DoShoutBackfire()  ; Активируем эффект обратного удара
    endif
EndEvent