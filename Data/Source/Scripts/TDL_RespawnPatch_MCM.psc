ScriptName TDL_RespawnPatch_MCM extends SKI_ConfigBase

TDL_RespawnPatchController Property Controller Auto

GlobalVariable Property TDL_Respawn_Mode Auto
GlobalVariable Property TDL_Respawn_iHoursToRespawnCell Auto
GlobalVariable Property TDL_Respawn_iHoursToRespawnCellCleared Auto

Int FLAG_HAS_DEFAULT = 16

Int MODE_DEFAULT = 1
Int MODE_CUSTOM = 2
Int MODE_FORCE = 3

; Mode 1 (Default) values (как было)
Int DEFAULT_CELL = 240
Int DEFAULT_CLEARED = 720

; Mode 3 (Force) values
Int FORCE_CELL = 2
Int FORCE_CLEARED = 3

; Slider "R/Default" values (как вы просите)
Int SLIDER_DEFAULT_CELL = 48
Int SLIDER_DEFAULT_CLEARED = 60

Int OID_Mode = -1
Int OID_CustomCell = -1
Int OID_CustomCleared = -1

Int OID_ActiveCell = -1
Int OID_ActiveCleared = -1
Int OID_ApplyNow = -1

Event OnConfigInit()
	Pages = new String[1]
	Pages[0] = "$TDL_Respawn_PageMain"
EndEvent

Event OnPageReset(String page)
	BuildPage()
EndEvent

Function BuildPage()
	SetCursorFillMode(TOP_TO_BOTTOM)

	SetCursorPosition(0)
	AddHeaderOption("$TDL_Respawn_HeaderMode")
	OID_Mode = AddMenuOption("$TDL_Respawn_Mode", _GetModeText(TDL_Respawn_Mode.GetValueInt()))
	OID_ApplyNow = AddTextOption("$TDL_Respawn_ApplyNow", "$TDL_Respawn_Apply")

	AddHeaderOption("$TDL_Respawn_HeaderCustom")
	OID_CustomCell = AddSliderOption("$TDL_Respawn_CellHours", TDL_Respawn_iHoursToRespawnCell.GetValueInt(), "{0}", FLAG_HAS_DEFAULT)
	OID_CustomCleared = AddSliderOption("$TDL_Respawn_ClearedHours", TDL_Respawn_iHoursToRespawnCellCleared.GetValueInt(), "{0}", FLAG_HAS_DEFAULT)

	SetCursorPosition(1)
	AddHeaderOption("$TDL_Respawn_HeaderActive")
	OID_ActiveCell = AddTextOption("$TDL_Respawn_ActiveCell", _GetActiveCellText())
	OID_ActiveCleared = AddTextOption("$TDL_Respawn_ActiveCleared", _GetActiveClearedText())
EndFunction

Event OnOptionSelect(Int option)
	If option == OID_ApplyNow
		If Controller
			Controller.ApplyCurrent()
		EndIf
		_RefreshActiveTexts()
	EndIf
EndEvent

Event OnOptionMenuOpen(Int option)
	If option == OID_Mode
		String[] opts = new String[3]
		opts[0] = _GetModeText(MODE_DEFAULT)
		opts[1] = _GetModeText(MODE_CUSTOM)
		opts[2] = _GetModeText(MODE_FORCE)
		SetMenuDialogOptions(opts)

		Int cur = TDL_Respawn_Mode.GetValueInt()
		Int idx = 0
		If cur == MODE_CUSTOM
			idx = 1
		EndIf
		If cur == MODE_FORCE
			idx = 2
		EndIf
		SetMenuDialogStartIndex(idx)
		SetMenuDialogDefaultIndex(0)
	EndIf
EndEvent

Event OnOptionMenuAccept(Int option, Int index)
	If option == OID_Mode
		Int newMode = MODE_DEFAULT
		If index == 1
			newMode = MODE_CUSTOM
		EndIf
		If index == 2
			newMode = MODE_FORCE
		EndIf

		TDL_Respawn_Mode.SetValueInt(newMode)
		SetMenuOptionValue(OID_Mode, _GetModeText(newMode))

		If Controller
			Controller.ApplyCurrent()
		EndIf
		_RefreshActiveTexts()
	EndIf
EndEvent

Event OnOptionSliderOpen(Int option)
	If option == OID_CustomCell
		Int curCell = TDL_Respawn_iHoursToRespawnCell.GetValueInt()
		If curCell < 1
			curCell = 1
		EndIf
		If curCell > 240
			curCell = 240
		EndIf

		SetSliderDialogRange(1, 240)
		SetSliderDialogInterval(1)
		SetSliderDialogDefaultValue(SLIDER_DEFAULT_CELL)
		SetSliderDialogStartValue(curCell)
	EndIf

	If option == OID_CustomCleared
		Int curCleared = TDL_Respawn_iHoursToRespawnCellCleared.GetValueInt()
		If curCleared < 1
			curCleared = 1
		EndIf
		If curCleared > 720
			curCleared = 720
		EndIf

		SetSliderDialogRange(1, 720)
		SetSliderDialogInterval(1)
		SetSliderDialogDefaultValue(SLIDER_DEFAULT_CLEARED)
		SetSliderDialogStartValue(curCleared)
	EndIf
EndEvent

Event OnOptionSliderAccept(Int option, Float value)
	If option == OID_CustomCell
		Int vCell = value as Int
		TDL_Respawn_iHoursToRespawnCell.SetValueInt(vCell)
		SetSliderOptionValue(OID_CustomCell, vCell, "{0}")
		If TDL_Respawn_Mode.GetValueInt() == MODE_CUSTOM
			If Controller
				Controller.ApplyCurrent()
			EndIf
		EndIf
		_RefreshActiveTexts()
	EndIf

	If option == OID_CustomCleared
		Int vCleared = value as Int
		TDL_Respawn_iHoursToRespawnCellCleared.SetValueInt(vCleared)
		SetSliderOptionValue(OID_CustomCleared, vCleared, "{0}")
		If TDL_Respawn_Mode.GetValueInt() == MODE_CUSTOM
			If Controller
				Controller.ApplyCurrent()
			EndIf
		EndIf
		_RefreshActiveTexts()
	EndIf
EndEvent

Event OnOptionDefault(Int option)
	If option == OID_CustomCell
		TDL_Respawn_iHoursToRespawnCell.SetValueInt(SLIDER_DEFAULT_CELL)
		SetSliderOptionValue(OID_CustomCell, SLIDER_DEFAULT_CELL, "{0}")
		If TDL_Respawn_Mode.GetValueInt() == MODE_CUSTOM
			If Controller
				Controller.ApplyCurrent()
			EndIf
		EndIf
		_RefreshActiveTexts()
	EndIf

	If option == OID_CustomCleared
		TDL_Respawn_iHoursToRespawnCellCleared.SetValueInt(SLIDER_DEFAULT_CLEARED)
		SetSliderOptionValue(OID_CustomCleared, SLIDER_DEFAULT_CLEARED, "{0}")
		If TDL_Respawn_Mode.GetValueInt() == MODE_CUSTOM
			If Controller
				Controller.ApplyCurrent()
			EndIf
		EndIf
		_RefreshActiveTexts()
	EndIf
EndEvent

Function _RefreshActiveTexts()
	If OID_ActiveCell != -1
		SetTextOptionValue(OID_ActiveCell, _GetActiveCellText())
	EndIf
	If OID_ActiveCleared != -1
		SetTextOptionValue(OID_ActiveCleared, _GetActiveClearedText())
	EndIf
EndFunction

String Function _GetActiveCellText()
	Int mode = TDL_Respawn_Mode.GetValueInt()
	If mode == MODE_DEFAULT
		Return "" + DEFAULT_CELL
	EndIf
	If mode == MODE_CUSTOM
		Return "" + TDL_Respawn_iHoursToRespawnCell.GetValueInt()
	EndIf
	If mode == MODE_FORCE
		Return "" + FORCE_CELL
	EndIf
	Return "" + DEFAULT_CELL
EndFunction

String Function _GetActiveClearedText()
	Int mode = TDL_Respawn_Mode.GetValueInt()
	If mode == MODE_DEFAULT
		Return "" + DEFAULT_CLEARED
	EndIf
	If mode == MODE_CUSTOM
		Return "" + TDL_Respawn_iHoursToRespawnCellCleared.GetValueInt()
	EndIf
	If mode == MODE_FORCE
		Return "" + FORCE_CLEARED
	EndIf
	Return "" + DEFAULT_CLEARED
EndFunction

String Function _GetModeText(Int mode)
	If mode == MODE_DEFAULT
		Return "$TDL_Respawn_ModeDefault"
	EndIf
	If mode == MODE_CUSTOM
		Return "$TDL_Respawn_ModeCustom"
	EndIf
	If mode == MODE_FORCE
		Return "$TDL_Respawn_ModeForce"
	EndIf
	Return "$TDL_Respawn_ModeDefault"
EndFunction