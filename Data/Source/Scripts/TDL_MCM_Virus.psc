ScriptName TDL_MCM_Virus extends Quest

; =====================================================
; TDL_MCM_Virus
; =====================================================

Quest Property MainControllerQuest Auto

; =========================
; GLOBALS
; =========================
GlobalVariable Property Virus_WerewolfDurationGV Auto
GlobalVariable Property Virus_WerewolfDamageMultGV Auto

; =========================
; CONSTANTS
; =========================
Int FLAG_HAS_DEFAULT = 16

; =========================
; OIDs — ACTIONS
; =========================
Int OID_Infect = -1
Int OID_Werewolf = -1
Int OID_Vampire = -1

; =========================
; OIDs — SETTINGS
; =========================
Int OID_WW_Duration = -1
Int OID_WW_DamageMult = -1


; =====================================================
; BUILD PAGE
; =====================================================
Function BuildPage(SKI_ConfigBase mcm)

	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	; ===== ACTIONS =====
	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$VirusHeaderActions")
	OID_Infect = mcm.AddTextOption("$VirusActionInfect", "$ActionActivate")
	OID_Werewolf = mcm.AddTextOption("$VirusActionWerewolf", "$ActionActivate")
	OID_Vampire = mcm.AddTextOption("$VirusActionVampire", "$ActionActivate")

	; ===== WEREWOLF SETTINGS =====
	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$VirusHeaderWerewolf")
	OID_WW_Duration = mcm.AddSliderOption("$VirusWerewolfDuration", Virus_WerewolfDurationGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_WW_DamageMult = mcm.AddSliderOption("$VirusWerewolfDamageMult", Virus_WerewolfDamageMultGV.GetValue(), "{1}", FLAG_HAS_DEFAULT)

EndFunction


; =====================================================
; ACTION BUTTONS
; =====================================================
Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)

	If MainControllerQuest == None
		Return False
	EndIf

	If option == OID_Infect
		MainControllerQuest.SetStage(100)
		Return True
	EndIf

	If option == OID_Werewolf
		MainControllerQuest.SetStage(101)
		Return True
	EndIf

	If option == OID_Vampire
		MainControllerQuest.SetStage(102)
		Return True
	EndIf

	Return False
EndFunction


; =====================================================
; SLIDER OPEN (RANGES)
; =====================================================
Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)

	If option == OID_WW_Duration
		mcm.SetSliderDialogRange(5, 600)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	If option == OID_WW_DamageMult
		mcm.SetSliderDialogRange(0.1, 3.0)
		mcm.SetSliderDialogInterval(0.1)
		Return True
	EndIf

	Return False
EndFunction


; =====================================================
; SLIDER ACCEPT
; =====================================================
Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)

	If option == OID_WW_Duration
		Virus_WerewolfDurationGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf

	If option == OID_WW_DamageMult
		Virus_WerewolfDamageMultGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{1}")
		Return True
	EndIf

	Return False
EndFunction


; =====================================================
; RESET TO DEFAULT (KEY R)
; =====================================================
Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)

	If option == OID_WW_Duration
		Virus_WerewolfDurationGV.SetValue(150)
		mcm.SetSliderOptionValue(option, 150, "{0}")
		Return True
	EndIf

	If option == OID_WW_DamageMult
		Virus_WerewolfDamageMultGV.SetValue(1.5)
		mcm.SetSliderOptionValue(option, 1.5, "{1}")
		Return True
	EndIf

	Return False
EndFunction