ScriptName TDL_MCM_Teleport extends Quest

; =====================================================
; TDL_MCM_Teleport
; MCM page for Teleport module
; =====================================================

Quest Property MainControllerQuest Auto

; =====================================================
; OIDs
; =====================================================

Int OID_RandomCityVillage = -1
Int OID_RandomLocation    = -1
Int OID_HighHrothgar      = -1

Int OID_Whiterun   = -1
Int OID_Solitude   = -1
Int OID_Windhelm   = -1
Int OID_Riften     = -1
Int OID_Markarth   = -1
Int OID_Falkreath  = -1
Int OID_Dawnstar   = -1


; =====================================================
; BUILD PAGE
; =====================================================
Function BuildPage(SKI_ConfigBase mcm)

	; Œ¡ﬂ«¿“≈À‹ÕŒ
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	; ---------------- LEFT COLUMN ----------------
	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$TeleportHeaderRandom")

	OID_RandomCityVillage = mcm.AddTextOption("$TeleportRandomCityVillage", "$ActionActivate")
	OID_RandomLocation    = mcm.AddTextOption("$TeleportRandomLocation", "$ActionActivate")

	mcm.AddHeaderOption("$TeleportHeaderSpecial")
	OID_HighHrothgar = mcm.AddTextOption("$TeleportHighHrothgar", "$ActionActivate")

	; ---------------- RIGHT COLUMN ----------------
	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$TeleportHeaderCities")

	OID_Whiterun  = mcm.AddTextOption("$TeleportWhiterun", "$ActionActivate")
	OID_Solitude  = mcm.AddTextOption("$TeleportSolitude", "$ActionActivate")
	OID_Windhelm  = mcm.AddTextOption("$TeleportWindhelm", "$ActionActivate")
	OID_Riften    = mcm.AddTextOption("$TeleportRiften", "$ActionActivate")
	OID_Markarth  = mcm.AddTextOption("$TeleportMarkarth", "$ActionActivate")
	OID_Falkreath = mcm.AddTextOption("$TeleportFalkreath", "$ActionActivate")
	OID_Dawnstar  = mcm.AddTextOption("$TeleportDawnstar", "$ActionActivate")

EndFunction


; =====================================================
; OPTION SELECT
; =====================================================
Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)

	If MainControllerQuest == None
		Return False
	EndIf

	If option == OID_RandomCityVillage
		MainControllerQuest.SetStage(90)
		Return True
	EndIf

	If option == OID_RandomLocation
		MainControllerQuest.SetStage(91)
		Return True
	EndIf

	If option == OID_HighHrothgar
		MainControllerQuest.SetStage(92)
		Return True
	EndIf

	If option == OID_Whiterun
		MainControllerQuest.SetStage(93)
		Return True
	EndIf

	If option == OID_Solitude
		MainControllerQuest.SetStage(94)
		Return True
	EndIf

	If option == OID_Windhelm
		MainControllerQuest.SetStage(95)
		Return True
	EndIf

	If option == OID_Riften
		MainControllerQuest.SetStage(96)
		Return True
	EndIf

	If option == OID_Markarth
		MainControllerQuest.SetStage(97)
		Return True
	EndIf

	If option == OID_Falkreath
		MainControllerQuest.SetStage(98)
		Return True
	EndIf

	If option == OID_Dawnstar
		MainControllerQuest.SetStage(99)
		Return True
	EndIf

	Return False
EndFunction


; =====================================================
; DEFAULT (NOT USED)
; =====================================================
Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)
	Return False
EndFunction