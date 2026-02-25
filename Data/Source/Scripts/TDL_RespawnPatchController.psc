ScriptName TDL_RespawnPatchController extends Quest

GlobalVariable Property GV_RespawnCell Auto
GlobalVariable Property GV_RespawnCellCleared Auto
GlobalVariable Property GV_Mode Auto

Int MODE_DEFAULT = 1
Int MODE_CUSTOM = 2
Int MODE_FORCE = 3

Int DEFAULT_CELL = 240
Int DEFAULT_CLEARED = 720

Int FORCE_CELL = 2
Int FORCE_CLEARED = 3

Int _prevMode = 1
Float _forceEndGameTime = 0.0

Event OnInit()
	If GV_Mode.GetValueInt() <= 0
		GV_Mode.SetValueInt(MODE_DEFAULT)
	EndIf
	ApplyCurrent()
EndEvent

Event OnPlayerLoadGame()
	_RestoreOrResumeForceWindow()
EndEvent

Function BeginTemporaryForce(Float hours)
	If hours <= 0.0
		hours = 2.0
	EndIf

	Float now = Utility.GetCurrentGameTime()
	_forceEndGameTime = now + (hours / 24.0)

	If GV_Mode.GetValueInt() != MODE_FORCE
		_prevMode = GV_Mode.GetValueInt()
		GV_Mode.SetValueInt(MODE_FORCE)
		ApplyCurrent()
	EndIf

	RegisterForSingleUpdateGameTime(hours)
EndFunction

Event OnUpdateGameTime()
	_RestoreOrResumeForceWindow()
EndEvent

Function _RestoreOrResumeForceWindow()
	If _forceEndGameTime <= 0.0
		Return
	EndIf

	Float now = Utility.GetCurrentGameTime()
	If now >= _forceEndGameTime
		_forceEndGameTime = 0.0
		GV_Mode.SetValueInt(_prevMode)
		ApplyCurrent()
		Return
	EndIf

	Float remainingHours = (_forceEndGameTime - now) * 24.0
	If remainingHours < 0.05
		remainingHours = 0.05
	EndIf

	GV_Mode.SetValueInt(MODE_FORCE)
	ApplyCurrent()
	RegisterForSingleUpdateGameTime(remainingHours)
EndFunction

Function ApplyCurrent()
	Int mode = GV_Mode.GetValueInt()
	If mode == MODE_DEFAULT
		_ApplyValues(DEFAULT_CELL, DEFAULT_CLEARED)
		Return
	EndIf
	If mode == MODE_CUSTOM
		_ApplyValues(GV_RespawnCell.GetValueInt(), GV_RespawnCellCleared.GetValueInt())
		Return
	EndIf
	If mode == MODE_FORCE
		_ApplyValues(FORCE_CELL, FORCE_CLEARED)
		Return
	EndIf
	_ApplyValues(DEFAULT_CELL, DEFAULT_CLEARED)
EndFunction

Function _ApplyValues(Int cellHours, Int clearedHours)
	If cellHours < 1
		cellHours = 1
	EndIf
	If clearedHours < 1
		clearedHours = 1
	EndIf
	ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCell " + cellHours)
	ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCellCleared " + clearedHours)
EndFunction