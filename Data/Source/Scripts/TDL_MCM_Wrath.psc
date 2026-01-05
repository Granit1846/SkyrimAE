ScriptName TDL_MCM_Wrath extends Quest

Quest Property MainControllerQuest Auto

GlobalVariable Property Wrath_TotalBurstsGV Auto
GlobalVariable Property Wrath_EffectIntervalGV Auto
GlobalVariable Property Wrath_RadiusGV Auto
GlobalVariable Property Wrath_ZOffsetGV Auto
GlobalVariable Property Wrath_DamageMinGV Auto
GlobalVariable Property Wrath_DamageMaxGV Auto
GlobalVariable Property Wrath_FireDamageMultGV Auto
GlobalVariable Property Wrath_StormMagickaMultGV Auto
GlobalVariable Property Wrath_FrostStaminaMultGV Auto
GlobalVariable Property Wrath_LevelScaleGV Auto
GlobalVariable Property Wrath_LevelCapGV Auto
GlobalVariable Property Wrath_ShakeChanceGV Auto
GlobalVariable Property Wrath_ShakeStrengthGV Auto
GlobalVariable Property Wrath_ShakeDurationGV Auto

Int FLAG_HAS_DEFAULT = 16

Int OID_Storm = -1
Int OID_Fire = -1
Int OID_Frost = -1

Int OID_Bursts = -1
Int OID_Interval = -1
Int OID_Radius = -1
Int OID_ZOffset = -1
Int OID_DmgMin = -1
Int OID_DmgMax = -1
Int OID_FireMult = -1
Int OID_StormMagMult = -1
Int OID_FrostStaMult = -1
Int OID_LevelScale = -1
Int OID_LevelCap = -1
Int OID_ShakeChance = -1
Int OID_ShakeStrength = -1
Int OID_ShakeDuration = -1

Function BuildPage(SKI_ConfigBase mcm)
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$WrathHeaderGeneral")
	OID_Bursts = mcm.AddSliderOption("$WrathTotalBursts", Wrath_TotalBurstsGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_Interval = mcm.AddSliderOption("$WrathInterval", Wrath_EffectIntervalGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_Radius = mcm.AddSliderOption("$WrathRadius", Wrath_RadiusGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_ZOffset = mcm.AddSliderOption("$WrathZOffset", Wrath_ZOffsetGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	
	mcm.AddHeaderOption("$WrathHeaderResources")
	OID_StormMagMult = mcm.AddSliderOption("$WrathStormMag", Wrath_StormMagickaMultGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_FrostStaMult = mcm.AddSliderOption("$WrathFrostSta", Wrath_FrostStaminaMultGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_LevelScale = mcm.AddSliderOption("$WrathLevelScale", Wrath_LevelScaleGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_LevelCap = mcm.AddSliderOption("$WrathLevelCap", Wrath_LevelCapGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)

mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$WrathHeaderActions")
	OID_Storm = mcm.AddTextOption("$WrathActionStorm", "$ActionActivate")
	OID_Fire = mcm.AddTextOption("$WrathActionFire", "$ActionActivate")
	OID_Frost = mcm.AddTextOption("$WrathActionFrost", "$ActionActivate")

	mcm.AddHeaderOption("$WrathHeaderDamage")
	OID_DmgMin = mcm.AddSliderOption("$WrathDamageMin", Wrath_DamageMinGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_DmgMax = mcm.AddSliderOption("$WrathDamageMax", Wrath_DamageMaxGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_FireMult = mcm.AddSliderOption("$WrathFireMult", Wrath_FireDamageMultGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)

	mcm.AddHeaderOption("$WrathHeaderCamera")
	OID_ShakeChance = mcm.AddSliderOption("$WrathShakeChance", Wrath_ShakeChanceGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_ShakeStrength = mcm.AddSliderOption("$WrathShakeStrength", Wrath_ShakeStrengthGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_ShakeDuration = mcm.AddSliderOption("$WrathShakeDuration", Wrath_ShakeDurationGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
EndFunction

; =========================
; ACTION BUTTONS
; =========================
Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)
	If MainControllerQuest == None
		Return False
	EndIf

	If option == OID_Storm
		MainControllerQuest.SetStage(11)
		Return True
	EndIf
	If option == OID_Fire
		MainControllerQuest.SetStage(12)
		Return True
	EndIf
	If option == OID_Frost
		MainControllerQuest.SetStage(13)
		Return True
	EndIf

	Return False
EndFunction

; =========================
; SLIDER OPEN (RANGES)
; =========================
Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)

	If option == OID_Bursts
		mcm.SetSliderDialogRange(1, 50)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_Interval
		mcm.SetSliderDialogRange(0.05, 2.0)
		mcm.SetSliderDialogInterval(0.05)
		Return True
	EndIf

	If option == OID_Radius
		mcm.SetSliderDialogRange(100, 2000)
		mcm.SetSliderDialogInterval(50)
		Return True
	EndIf

	If option == OID_ZOffset
		mcm.SetSliderDialogRange(0, 500)
		mcm.SetSliderDialogInterval(10)
		Return True
	EndIf

	If option == OID_DmgMin || option == OID_DmgMax
		mcm.SetSliderDialogRange(1, 100)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_FireMult || option == OID_StormMagMult || option == OID_FrostStaMult
		mcm.SetSliderDialogRange(0.0, 5.0)
		mcm.SetSliderDialogInterval(0.05)
		Return True
	EndIf

	If option == OID_LevelScale
		mcm.SetSliderDialogRange(0.0, 0.10)
		mcm.SetSliderDialogInterval(0.005)
		Return True
	EndIf

	If option == OID_LevelCap
		mcm.SetSliderDialogRange(1.0, 5.0)
		mcm.SetSliderDialogInterval(0.1)
		Return True
	EndIf

	If option == OID_ShakeChance
		mcm.SetSliderDialogRange(0, 100)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	If option == OID_ShakeStrength || option == OID_ShakeDuration
		mcm.SetSliderDialogRange(0.0, 1.0)
		mcm.SetSliderDialogInterval(0.05)
		Return True
	EndIf

	Return False
EndFunction

; =========================
; SLIDER ACCEPT
; =========================
Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)

	If option == OID_Bursts
		Wrath_TotalBurstsGV.SetValueInt(value as Int)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	If option == OID_Interval
		Wrath_EffectIntervalGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	If option == OID_Radius
		Wrath_RadiusGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	If option == OID_ZOffset
		Wrath_ZOffsetGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	If option == OID_DmgMin
		Wrath_DamageMinGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	If option == OID_DmgMax
		Wrath_DamageMaxGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	If option == OID_FireMult
		Wrath_FireDamageMultGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	If option == OID_StormMagMult
		Wrath_StormMagickaMultGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	If option == OID_FrostStaMult
		Wrath_FrostStaminaMultGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	If option == OID_LevelScale
		Wrath_LevelScaleGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	If option == OID_LevelCap
		Wrath_LevelCapGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	If option == OID_ShakeChance
		Wrath_ShakeChanceGV.SetValueInt(value as Int)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	If option == OID_ShakeStrength
		Wrath_ShakeStrengthGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	If option == OID_ShakeDuration
		Wrath_ShakeDurationGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf

	Return False
EndFunction

; =========================
; RESET TO DEFAULT (KEY R)
; =========================
Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)

	If option == OID_Bursts
		Wrath_TotalBurstsGV.SetValueInt(6)
		mcm.SetSliderOptionValue(option, 6, "{0}")
		Return True
	EndIf

	If option == OID_Interval
		Wrath_EffectIntervalGV.SetValue(0.4)
		mcm.SetSliderOptionValue(option, 0.4, "{2}")
		Return True
	EndIf

	If option == OID_Radius
		Wrath_RadiusGV.SetValue(300)
		mcm.SetSliderOptionValue(option, 300, "{0}")
		Return True
	EndIf

	If option == OID_ZOffset
		Wrath_ZOffsetGV.SetValue(50)
		mcm.SetSliderOptionValue(option, 50, "{0}")
		Return True
	EndIf

	If option == OID_DmgMin
		Wrath_DamageMinGV.SetValue(5)
		mcm.SetSliderOptionValue(option, 5, "{0}")
		Return True
	EndIf

	If option == OID_DmgMax
		Wrath_DamageMaxGV.SetValue(15)
		mcm.SetSliderOptionValue(option, 15, "{0}")
		Return True
	EndIf

	If option == OID_FireMult
		Wrath_FireDamageMultGV.SetValue(1.0)
		mcm.SetSliderOptionValue(option, 1.0, "{2}")
		Return True
	EndIf

	If option == OID_StormMagMult
		Wrath_StormMagickaMultGV.SetValue(1.0)
		mcm.SetSliderOptionValue(option, 1.0, "{2}")
		Return True
	EndIf

	If option == OID_FrostStaMult
		Wrath_FrostStaminaMultGV.SetValue(1.0)
		mcm.SetSliderOptionValue(option, 1.0, "{2}")
		Return True
	EndIf

	If option == OID_LevelScale
		Wrath_LevelScaleGV.SetValue(0.0)
		mcm.SetSliderOptionValue(option, 0.0, "{2}")
		Return True
	EndIf

	If option == OID_LevelCap
		Wrath_LevelCapGV.SetValue(3.0)
		mcm.SetSliderOptionValue(option, 3.0, "{2}")
		Return True
	EndIf

	If option == OID_ShakeChance
		Wrath_ShakeChanceGV.SetValueInt(0)
		mcm.SetSliderOptionValue(option, 0, "{0}")
		Return True
	EndIf

	If option == OID_ShakeStrength
		Wrath_ShakeStrengthGV.SetValue(0.0)
		mcm.SetSliderOptionValue(option, 0.0, "{2}")
		Return True
	EndIf

	If option == OID_ShakeDuration
		Wrath_ShakeDurationGV.SetValue(0.0)
		mcm.SetSliderOptionValue(option, 0.0, "{2}")
		Return True
	EndIf

	Return False
EndFunction