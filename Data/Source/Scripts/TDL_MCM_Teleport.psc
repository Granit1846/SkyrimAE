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

Int OID_RespawnMode          = -1
Int OID_RespawnApply         = -1
Int OID_RespawnCell          = -1
Int OID_RespawnCleared       = -1
Int OID_RespawnActiveCell    = -1
Int OID_RespawnActiveCleared = -1

Int SLIDER_DEFAULT_CELL = 48
Int SLIDER_DEFAULT_CLEARED = 60


; =====================================================
; BUILD PAGE
; =====================================================
Function BuildPage(SKI_ConfigBase mcm)

	; ÎÁßÇÀÒÅËÜÍÎ
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	; ---------------- LEFT COLUMN ----------------
	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$TeleportHeaderRandom")

	OID_RandomCityVillage = mcm.AddTextOption("$TeleportRandomCityVillage", "$ActionActivate")
	OID_RandomLocation    = mcm.AddTextOption("$TeleportRandomLocation", "$ActionActivate")

	mcm.AddHeaderOption("$TeleportHeaderSpecial")
	OID_HighHrothgar = mcm.AddTextOption("$TeleportHighHrothgar", "$ActionActivate")

	; Respawn settings (formerly the separate TDL_RespawningEncounterZones.esp menu)
	TDL_Teleport tp = MainControllerQuest as TDL_Teleport
	If tp
		mcm.AddHeaderOption("$TDL_Respawn_HeaderMode")
		OID_RespawnMode  = mcm.AddTextOption("$TDL_Respawn_Mode", _ModeText(tp.GetRespawnMode()))
		OID_RespawnApply = mcm.AddTextOption("$TDL_Respawn_ApplyNow", "$TDL_Respawn_Apply")
		mcm.AddHeaderOption("$TDL_Respawn_HeaderCustom")
		OID_RespawnCell    = mcm.AddSliderOption("$TDL_Respawn_CellHours", tp.GetRespawnCustomCell(), "{0}")
		OID_RespawnCleared = mcm.AddSliderOption("$TDL_Respawn_ClearedHours", tp.GetRespawnCustomCleared(), "{0}")
		mcm.AddHeaderOption("$TDL_Respawn_HeaderActive")
		OID_RespawnActiveCell    = mcm.AddTextOption("$TDL_Respawn_ActiveCell", "" + tp.GetRespawnActiveCell())
		OID_RespawnActiveCleared = mcm.AddTextOption("$TDL_Respawn_ActiveCleared", "" + tp.GetRespawnActiveCleared())
	EndIf

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

	TDL_Teleport tp = MainControllerQuest as TDL_Teleport
	If tp && option == OID_RespawnMode
		Int mode = tp.GetRespawnMode() + 1
		If mode > 3
			mode = 1
		EndIf
		tp.SetRespawnMode(mode)
		mcm.SetTextOptionValue(OID_RespawnMode, _ModeText(mode))
		_RefreshActive(mcm, tp)
		Return True
	EndIf

	If tp && option == OID_RespawnApply
		tp.RespawnApplyCurrent()
		_RefreshActive(mcm, tp)
		Return True
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
; RESPAWN SLIDERS / DEFAULT
; =====================================================
Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)
	TDL_Teleport tp = MainControllerQuest as TDL_Teleport
	If !tp
		Return False
	EndIf
	If option == OID_RespawnCell
		mcm.SetSliderDialogStartValue(tp.GetRespawnCustomCell())
		mcm.SetSliderDialogDefaultValue(SLIDER_DEFAULT_CELL)
		mcm.SetSliderDialogRange(1, 240)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf
	If option == OID_RespawnCleared
		mcm.SetSliderDialogStartValue(tp.GetRespawnCustomCleared())
		mcm.SetSliderDialogDefaultValue(SLIDER_DEFAULT_CLEARED)
		mcm.SetSliderDialogRange(1, 720)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)
	TDL_Teleport tp = MainControllerQuest as TDL_Teleport
	If !tp
		Return False
	EndIf
	If option == OID_RespawnCell
		tp.SetRespawnCustom(value as Int, tp.GetRespawnCustomCleared())
		mcm.SetSliderOptionValue(OID_RespawnCell, value, "{0}")
		_RefreshActive(mcm, tp)
		Return True
	EndIf
	If option == OID_RespawnCleared
		tp.SetRespawnCustom(tp.GetRespawnCustomCell(), value as Int)
		mcm.SetSliderOptionValue(OID_RespawnCleared, value, "{0}")
		_RefreshActive(mcm, tp)
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)
	If option == OID_RespawnCell
		Return HandleSliderAccept(mcm, option, SLIDER_DEFAULT_CELL)
	EndIf
	If option == OID_RespawnCleared
		Return HandleSliderAccept(mcm, option, SLIDER_DEFAULT_CLEARED)
	EndIf
	Return False
EndFunction

Function _RefreshActive(SKI_ConfigBase mcm, TDL_Teleport tp)
	mcm.SetTextOptionValue(OID_RespawnActiveCell, "" + tp.GetRespawnActiveCell())
	mcm.SetTextOptionValue(OID_RespawnActiveCleared, "" + tp.GetRespawnActiveCleared())
EndFunction

String Function _ModeText(Int mode)
	If mode == 2
		Return "$TDL_Respawn_ModeCustom"
	ElseIf mode == 3
		Return "$TDL_Respawn_ModeForce"
	EndIf
	Return "$TDL_Respawn_ModeDefault"
EndFunction