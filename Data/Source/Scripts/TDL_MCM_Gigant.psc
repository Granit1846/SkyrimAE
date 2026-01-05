ScriptName TDL_MCM_Gigant extends Quest

Quest Property MainControllerQuest Auto

; =========================
; GLOBALS — SCALE / DAMAGE
; =========================
GlobalVariable Property Gigant_ScaleBigGV Auto
GlobalVariable Property Gigant_ScaleSmallGV Auto
GlobalVariable Property Gigant_DamageBigGV Auto
GlobalVariable Property Gigant_DamageSmallGV Auto

; =========================
; GLOBALS — SPEED
; =========================
GlobalVariable Property Gigant_SpeedMultGV Auto
GlobalVariable Property Gigant_SpeedSlowGV Auto

; =========================
; GLOBALS — DURATION (NEW)
; =========================
GlobalVariable Property Gigant_SizeDurationGV Auto
GlobalVariable Property Gigant_SpeedDurationGV Auto

Int FLAG_HAS_DEFAULT = 16

; =========================
; ACTION OIDs
; =========================
Int OID_Big   = -1
Int OID_Small = -1
Int OID_Speed = -1
Int OID_Slow  = -1
Int OID_Reset = -1

; =========================
; VALUE OIDs
; =========================
Int OID_ScaleBig      = -1
Int OID_ScaleSmall    = -1
Int OID_DmgBig        = -1
Int OID_DmgSmall      = -1
Int OID_SpeedFast     = -1
Int OID_SpeedSlow     = -1
Int OID_SizeDuration  = -1
Int OID_SpeedDuration = -1

; =========================
; BUILD PAGE
; =========================
Function BuildPage(SKI_ConfigBase mcm)
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	; ---------- SIZE ----------
	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$GigantHeaderActions")

	OID_Big = mcm.AddTextOption("$GigantActionBig", "$ActionActivate")
	OID_ScaleBig = mcm.AddSliderOption("$GigantScaleBig", Gigant_ScaleBigGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_DmgBig = mcm.AddSliderOption("$GigantDamageBig", Gigant_DamageBigGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)

	Int spacer = mcm.AddTextOption("", "")
	mcm.SetOptionFlags(spacer, mcm.OPTION_FLAG_DISABLED)

	OID_Small = mcm.AddTextOption("$GigantActionSmall", "$ActionActivate")
	OID_ScaleSmall = mcm.AddSliderOption("$GigantScaleSmall", Gigant_ScaleSmallGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_DmgSmall = mcm.AddSliderOption("$GigantDamageSmall", Gigant_DamageSmallGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)

	OID_SizeDuration = mcm.AddSliderOption("$GigantSizeDuration", Gigant_SizeDurationGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	OID_Reset = mcm.AddTextOption("$GigantActionReset", "$ActionReset")

	; ---------- SPEED ----------
	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$GigantHeaderSpeed")

	OID_Speed = mcm.AddTextOption("$GigantActionSpeed", "$ActionActivate")
	OID_SpeedFast = mcm.AddSliderOption("$GigantSpeedFast", Gigant_SpeedMultGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	OID_Slow = mcm.AddTextOption("$GigantActionSlow", "$ActionActivate")
	OID_SpeedSlow = mcm.AddSliderOption("$GigantSpeedSlow", Gigant_SpeedSlowGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	OID_SpeedDuration = mcm.AddSliderOption("$GigantSpeedDuration", Gigant_SpeedDurationGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
EndFunction

; =========================
; ACTION HANDLER
; =========================
Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)
	If MainControllerQuest == None
		Return False
	EndIf

	If option == OID_Big
		MainControllerQuest.SetStage(120)
		Return True
	EndIf
	If option == OID_Small
		MainControllerQuest.SetStage(121)
		Return True
	EndIf
	If option == OID_Speed
		MainControllerQuest.SetStage(122)
		Return True
	EndIf
	If option == OID_Slow
		MainControllerQuest.SetStage(123)
		Return True
	EndIf
	If option == OID_Reset
		MainControllerQuest.SetStage(124)
		Return True
	EndIf

	Return False
EndFunction

; =========================
; SLIDER OPEN
; =========================
Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)
	If option == OID_ScaleBig || option == OID_ScaleSmall
		mcm.SetSliderDialogRange(0.1, 5.0)
		mcm.SetSliderDialogInterval(0.05)
		Return True
	EndIf

	If option == OID_DmgBig || option == OID_DmgSmall
		mcm.SetSliderDialogRange(0.0, 10.0)
		mcm.SetSliderDialogInterval(0.1)
		Return True
	EndIf

	If option == OID_SpeedFast || option == OID_SpeedSlow
		mcm.SetSliderDialogRange(1.0, 500.0)
		mcm.SetSliderDialogInterval(5.0)
		Return True
	EndIf

	If option == OID_SizeDuration || option == OID_SpeedDuration
		mcm.SetSliderDialogRange(5, 600)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	Return False
EndFunction

; =========================
; SLIDER ACCEPT
; =========================
Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)
	If option == OID_ScaleBig
		Gigant_ScaleBigGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_ScaleSmall
		Gigant_ScaleSmallGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_DmgBig
		Gigant_DamageBigGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_DmgSmall
		Gigant_DamageSmallGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_SpeedFast
		Gigant_SpeedMultGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_SpeedSlow
		Gigant_SpeedSlowGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_SizeDuration
		Gigant_SizeDurationGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_SpeedDuration
		Gigant_SpeedDurationGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	Return False
EndFunction

; =========================
; DEFAULTS (R KEY)
; =========================
Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)
	If option == OID_SizeDuration
		Gigant_SizeDurationGV.SetValue(60)
		mcm.SetSliderOptionValue(option, 60, "{0}")
		Return True
	EndIf
	If option == OID_SpeedDuration
		Gigant_SpeedDurationGV.SetValue(60)
		mcm.SetSliderOptionValue(option, 60, "{0}")
		Return True
	EndIf

	Return False
EndFunction