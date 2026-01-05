ScriptName TDL_MCM_Chaos extends Quest

Quest Property MainControllerQuest Auto
GlobalVariable Property TDL_DebugEnabled Auto

GlobalVariable Property Backfire_ChanceGV Auto
GlobalVariable Property Backfire_DurationGV Auto
GlobalVariable Property ShoutPushForceGV Auto
GlobalVariable Property ShoutPushDelayGV Auto
GlobalVariable Property KnockbackForceGV Auto
GlobalVariable Property KnockbackCooldownGV Auto
GlobalVariable Property KnockbackRadiusGV Auto
GlobalVariable Property KnockbackMeleeDelayGV Auto
GlobalVariable Property KnockbackBowDelayGV Auto

Int FLAG_HAS_DEFAULT = 16

Int OID_StartLowG
Int OID_StartBackfire
Int OID_Debug

Int OID_BackfireChance
Int OID_BackfireDuration
Int OID_ShoutPushForce
Int OID_ShoutPushDelay
Int OID_KnockbackForce
Int OID_KnockbackCooldown
Int OID_KnockbackRadius
Int OID_KnockbackMeleeDelay
Int OID_KnockbackBowDelay

Function BuildPage(SKI_ConfigBase mcm)

	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$ChaosHeaderLowG")
	OID_StartLowG = mcm.AddTextOption("$ChaosActionLowG", "$ActionStart")
	mcm.AddHeaderOption("$ChaosHeaderDebug")
	OID_Debug = mcm.AddToggleOption("$ChaosDebug", (TDL_DebugEnabled.GetValueInt() == 1))

	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$ChaosHeaderBackfire")
	OID_StartBackfire = mcm.AddTextOption("$ChaosActionBackfire", "$ActionStart")
	OID_BackfireChance = mcm.AddSliderOption("$ChaosBackfireChance", Backfire_ChanceGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_BackfireDuration = mcm.AddSliderOption("$ChaosBackfireDuration", Backfire_DurationGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	mcm.AddHeaderOption("$ChaosHeaderShout")
	OID_ShoutPushForce = mcm.AddSliderOption("$ChaosShoutForce", ShoutPushForceGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_ShoutPushDelay = mcm.AddSliderOption("$ChaosShoutDelay", ShoutPushDelayGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	mcm.AddHeaderOption("$ChaosHeaderKnockback")
	OID_KnockbackForce = mcm.AddSliderOption("$ChaosKnockbackForce", KnockbackForceGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_KnockbackCooldown = mcm.AddSliderOption("$ChaosKnockbackCooldown", KnockbackCooldownGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_KnockbackRadius = mcm.AddSliderOption("$ChaosKnockbackRadius", KnockbackRadiusGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_KnockbackMeleeDelay = mcm.AddSliderOption("$ChaosMeleeDelay", KnockbackMeleeDelayGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_KnockbackBowDelay = mcm.AddSliderOption("$KnockbackBowDelay",KnockbackBowDelayGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)

EndFunction

Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)
	If option == OID_StartLowG
		MainControllerQuest.SetStage(70)
		Return True
	EndIf
	If option == OID_StartBackfire
		MainControllerQuest.SetStage(71)
		Return True
	EndIf
	If option == OID_Debug
		Int nv = 1
		If TDL_DebugEnabled.GetValueInt() == 1
			nv = 0
		EndIf
		TDL_DebugEnabled.SetValueInt(nv)
		mcm.SetToggleOptionValue(OID_Debug, (nv == 1))
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)
	If option == OID_BackfireChance
		Backfire_ChanceGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_BackfireDuration
		Backfire_DurationGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ShoutPushForce
		ShoutPushForceGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ShoutPushDelay
		ShoutPushDelayGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_KnockbackForce
		KnockbackForceGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_KnockbackCooldown
		KnockbackCooldownGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_KnockbackRadius
		KnockbackRadiusGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_KnockbackMeleeDelay
		KnockbackMeleeDelayGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_KnockbackBowDelay
		KnockbackBowDelayGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)
	If option == OID_BackfireChance
		Backfire_ChanceGV.SetValue(20)
		mcm.SetSliderOptionValue(option, 20, "{0}")
		Return True
	EndIf
	If option == OID_BackfireDuration
		Backfire_DurationGV.SetValue(60)
		mcm.SetSliderOptionValue(option, 60, "{0}")
		Return True
	EndIf
	If option == OID_ShoutPushForce
		ShoutPushForceGV.SetValue(20)
		mcm.SetSliderOptionValue(option, 20, "{0}")
		Return True
	EndIf
	If option == OID_ShoutPushDelay
		ShoutPushDelayGV.SetValue(0.05)
		mcm.SetSliderOptionValue(option, 0.05, "{2}")
		Return True
	EndIf
	If option == OID_KnockbackForce
		KnockbackForceGV.SetValue(25)
		mcm.SetSliderOptionValue(option, 25, "{0}")
		Return True
	EndIf
	If option == OID_KnockbackCooldown
		KnockbackCooldownGV.SetValue(0.35)
		mcm.SetSliderOptionValue(option, 0.35, "{2}")
		Return True
	EndIf
	If option == OID_KnockbackRadius
		KnockbackRadiusGV.SetValue(900)
		mcm.SetSliderOptionValue(option, 900, "{0}")
		Return True
	EndIf
	If option == OID_KnockbackMeleeDelay
		KnockbackMeleeDelayGV.SetValue(0.10)
		mcm.SetSliderOptionValue(option, 0.10, "{2}")
		Return True
	EndIf
	If option == OID_KnockbackBowDelay
		KnockbackBowDelayGV.SetValue(0.10)
		mcm.SetSliderOptionValue(option, 0.10, "{2}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)

	; ===== BACKFIRE =====
	If option == OID_BackfireChance
		mcm.SetSliderDialogRange(0, 100)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	If option == OID_BackfireDuration
		mcm.SetSliderDialogRange(1, 600)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	; ===== SHOUT PUSH =====
	If option == OID_ShoutPushForce
		mcm.SetSliderDialogRange(0, 200)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	If option == OID_ShoutPushDelay
		mcm.SetSliderDialogRange(0.0, 0.5)
		mcm.SetSliderDialogInterval(0.01)
		Return True
	EndIf

	; ===== ENEMY KNOCKBACK =====
	If option == OID_KnockbackForce
		mcm.SetSliderDialogRange(0, 200)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	If option == OID_KnockbackCooldown
		mcm.SetSliderDialogRange(0.0, 2.0)
		mcm.SetSliderDialogInterval(0.05)
		Return True
	EndIf

	If option == OID_KnockbackRadius
		mcm.SetSliderDialogRange(0, 20000)
		mcm.SetSliderDialogInterval(100)
		Return True
	EndIf

	; ===== MELEE =====
	If option == OID_KnockbackMeleeDelay
		mcm.SetSliderDialogRange(0.0, 0.5)
		mcm.SetSliderDialogInterval(0.01)
		Return True
	EndIf
	If option == OID_KnockbackBowDelay
		mcm.SetSliderDialogRange(0.0, 0.5)
		mcm.SetSliderDialogInterval(0.01)
		Return True
	EndIf

	Return False
EndFunction