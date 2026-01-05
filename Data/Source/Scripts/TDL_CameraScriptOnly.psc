Scriptname TDL_CameraScriptOnly extends Quest

; =========================
; DEBUG
; =========================
GlobalVariable Property TDL_DebugEnabled Auto
Function _Notify(String msg)
	If !TDL_DebugEnabled || TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification(msg)
	EndIf
EndFunction

; =========================
; MODES
; =========================
Int Property MODE_DEFAULT = 0 AutoReadOnly
Int Property MODE_BIG     = 1 AutoReadOnly
Int Property MODE_SMALL   = 2 AutoReadOnly

Int _currentMode = 0
Bool _active = False

; =========================
; ORIGINAL VALUES
; =========================
Float _origCX = 0.0
Float _origCY = 0.0
Float _origCZ = 0.0
Bool _origCaptured = False

; =========================
; PUBLIC API
; =========================
Function SetCameraMode(Int mode)
	If !_origCaptured
		_CaptureOriginal()
	EndIf

	_currentMode = mode

	If mode == MODE_DEFAULT
		_StopCamera()
		Return
	EndIf

	_active = True
	_ApplyCamera()

	RegisterForSingleUpdate(0.15)
EndFunction

; =========================
; CORE
; =========================
Function _CaptureOriginal()
	_origCX = Game.GetGameSettingFloat("fOverShoulderCombatPosX")
	_origCY = Game.GetGameSettingFloat("fOverShoulderCombatPosY")
	_origCZ = Game.GetGameSettingFloat("fOverShoulderCombatPosZ")
	_origCaptured = True
EndFunction

Function _ApplyCamera()
	Float x = _origCX
	Float y = _origCY
	Float z = _origCZ

	If _currentMode == MODE_BIG
		x = 150.0
		z = 200.0
	ElseIf _currentMode == MODE_SMALL
		x = 0.0
		z = -40.0
	EndIf

	Game.SetGameSettingFloat("fOverShoulderCombatPosX", x)
	Game.SetGameSettingFloat("fOverShoulderCombatPosY", y)
	Game.SetGameSettingFloat("fOverShoulderCombatPosZ", z)
EndFunction

Function _StopCamera()
	_active = False

	Game.SetGameSettingFloat("fOverShoulderCombatPosX", _origCX)
	Game.SetGameSettingFloat("fOverShoulderCombatPosY", _origCY)
	Game.SetGameSettingFloat("fOverShoulderCombatPosZ", _origCZ)
EndFunction

; =========================
; UPDATE LOOP
; =========================
Event OnUpdate()
	If !_active
		Return
	EndIf

	; поддерживаем смещение (движок может сбрасывать)
	_ApplyCamera()

	RegisterForSingleUpdate(0.15)
EndEvent