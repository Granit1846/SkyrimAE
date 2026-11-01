Scriptname TDL_Teleport extends Quest

; =====================================================
; TDL_Teleport
;
; Stages:
; 90 Ц Random City / Village
; 91 Ц Random Location + Message + GodBuff (20s)
; 92 Ц High Hrothgar
; 93 Ц Whiterun
; 94 Ц Solitude
; 95 Ц Windhelm
; 96 Ц Riften
; 97 Ц Markarth
; 98 Ц Falkreath
; 99 Ц Dawnstar
; =====================================================


; =====================================================
; PROPERTIES (CK)
; =====================================================

; ---------- RANDOM LISTS ----------
FormList Property TDL_Teleport_CitiesAndVillages Auto
FormList Property TDL_Teleport_RandomLocations Auto

; ---------- FIXED MARKERS ----------
ObjectReference Property Marker_HighHrothgar Auto

ObjectReference Property Marker_Whiterun Auto
ObjectReference Property Marker_Solitude Auto
ObjectReference Property Marker_Windhelm Auto
ObjectReference Property Marker_Riften Auto
ObjectReference Property Marker_Markarth Auto
ObjectReference Property Marker_Falkreath Auto
ObjectReference Property Marker_Dawnstar Auto

; ---------- SAFETY ----------
Spell   Property TDL_GodBuff Auto
Message Property TDL_Teleport_RandomWarningMsg Auto



; =====================================================
; INTERNAL STATE (safety timer)
; =====================================================
Bool  _safetyActive = false
Float _safetyEndRT = 0.0

; =====================================================
; INTERNAL STATE (respawn force window)
; =====================================================
; Respawn settings (formerly TDL_RespawningEncounterZones.esp), kept in the save
Int   _respawnMode = 1
Int   _respawnCustomCell = 48
Int   _respawnCustomCleared = 60
; Engine values before a force window in default mode (another mod may have changed them)
Int   _respawnSavedCell = 0
Int   _respawnSavedCleared = 0
Float _respawnForceEndGT = 0.0

Int MODE_DEFAULT = 1
Int MODE_CUSTOM = 2
Int MODE_FORCE = 3

Int DEFAULT_CELL = 240
Int DEFAULT_CLEARED = 720

Int FORCE_CELL = 2
Int FORCE_CLEARED = 3


; =====================================================
; ENTRY POINT
; =====================================================
Bool Function RunStage(Int aiStage, Actor playerRef)
	If !playerRef
		playerRef = Game.GetPlayer()
	EndIf
	If !playerRef
		Return False
	EndIf

	; ===== STAGE 90 =====
	If aiStage == 90
		Return _TeleportRandomFromList(TDL_Teleport_CitiesAndVillages, playerRef)

	; ===== STAGE 91 =====
	ElseIf aiStage == 91
		If !_TeleportRandomFromList(TDL_Teleport_RandomLocations, playerRef)
			Return False
		EndIf

		; Fast respawn for 2 game hours, then the chosen mode returns
		RespawnBeginTemporaryForce(2.0)

		If TDL_Teleport_RandomWarningMsg
			TDL_Teleport_RandomWarningMsg.Show()
		EndIf

		_ApplySafetyBuff(playerRef, 20.0)
		Return True

	; ===== STAGE 92 =====
	ElseIf aiStage == 92
		Return _TeleportToMarker(Marker_HighHrothgar, playerRef)

	; ===== BIG CITIES =====
	ElseIf aiStage == 93
		Return _TeleportToMarker(Marker_Whiterun, playerRef)
	ElseIf aiStage == 94
		Return _TeleportToMarker(Marker_Solitude, playerRef)
	ElseIf aiStage == 95
		Return _TeleportToMarker(Marker_Windhelm, playerRef)
	ElseIf aiStage == 96
		Return _TeleportToMarker(Marker_Riften, playerRef)
	ElseIf aiStage == 97
		Return _TeleportToMarker(Marker_Markarth, playerRef)
	ElseIf aiStage == 98
		Return _TeleportToMarker(Marker_Falkreath, playerRef)
	ElseIf aiStage == 99
		Return _TeleportToMarker(Marker_Dawnstar, playerRef)
	EndIf

	Return False
EndFunction


; =====================================================
; RANDOM TELEPORT
; =====================================================
Bool Function _TeleportRandomFromList(FormList lst, Actor p)
	If lst == None || lst.GetSize() <= 0
		Debug.Notification("TDL Teleport: destination list empty")
		Return False
	EndIf

	Int idx = Utility.RandomInt(0, lst.GetSize() - 1)
	ObjectReference marker = lst.GetAt(idx) as ObjectReference
	If marker == None
		Debug.Notification("TDL Teleport: invalid marker in list")
		Return False
	EndIf

	p.MoveTo(marker)
	Return True
EndFunction


; =====================================================
; FIXED TELEPORT
; =====================================================
Bool Function _TeleportToMarker(ObjectReference marker, Actor p)
	If marker == None
		Debug.Notification("TDL Teleport: marker not set")
		Return False
	EndIf

	p.MoveTo(marker)
	Return True
EndFunction


; =====================================================
; SAFETY BUFF (CAST + DISPEL)
; =====================================================
Function _ApplySafetyBuff(Actor p, Float duration)
	If TDL_GodBuff == None
		Return
	EndIf

	; если уже активен Ч просто продлеваем
	If _safetyActive
		_safetyEndRT = Utility.GetCurrentRealTime() + duration
		RegisterForSingleUpdate(1.0)
		Return
	EndIf

	; правильно: Cast, а не AddSpell
	TDL_GodBuff.Cast(p, p)

	_safetyActive = true
	_safetyEndRT = Utility.GetCurrentRealTime() + duration

	RegisterForSingleUpdate(1.0)
EndFunction


; =====================================================
; UPDATE LOOP (safety only)
; =====================================================
Event OnUpdate()
	If !_safetyActive
		Return
	EndIf

	Actor p = Game.GetPlayer()
	If p == None
		_ClearSafety()
		Return
	EndIf

	If Utility.GetCurrentRealTime() >= _safetyEndRT
		p.DispelSpell(TDL_GodBuff)
		_ClearSafety()
		Return
	EndIf

	RegisterForSingleUpdate(1.0)
EndEvent


Function _ClearSafety()
	_safetyActive = false
	_safetyEndRT = 0.0
EndFunction


; =====================================================
; RESPAWN (formerly TDL_RespawningEncounterZones.esp)
; Modes: 1 = game default, 2 = custom hours (MCM), 3 = always fast.
; A temporary force window (random teleport, fast travel) uses fast respawn for N game hours,
; then the chosen mode returns. Game settings are not saved, so the player alias
; (TDL_ChaosAliasScript) calls RespawnOnGameLoad on every load.
; =====================================================
Int Function GetRespawnMode()
	Return _respawnMode
EndFunction

Int Function GetRespawnCustomCell()
	Return _respawnCustomCell
EndFunction

Int Function GetRespawnCustomCleared()
	Return _respawnCustomCleared
EndFunction

Function SetRespawnMode(Int mode)
	If mode < MODE_DEFAULT || mode > MODE_FORCE
		mode = MODE_DEFAULT
	EndIf
	_respawnMode = mode
	RespawnApplyCurrent()
EndFunction

Function SetRespawnCustom(Int cellHours, Int clearedHours)
	_respawnCustomCell = cellHours
	_respawnCustomCleared = clearedHours
	If _respawnMode == MODE_CUSTOM
		RespawnApplyCurrent()
	EndIf
EndFunction

; Values in effect right now: a force window wins over the chosen mode
Int Function GetRespawnActiveCell()
	If _respawnForceEndGT > 0.0 || _respawnMode == MODE_FORCE
		Return FORCE_CELL
	ElseIf _respawnMode == MODE_CUSTOM
		Return _respawnCustomCell
	EndIf
	Return DEFAULT_CELL
EndFunction

Int Function GetRespawnActiveCleared()
	If _respawnForceEndGT > 0.0 || _respawnMode == MODE_FORCE
		Return FORCE_CLEARED
	ElseIf _respawnMode == MODE_CUSTOM
		Return _respawnCustomCleared
	EndIf
	Return DEFAULT_CLEARED
EndFunction

Function RespawnApplyCurrent()
	; Default mode outside a window: give back what the game (or another mod) had
	If _respawnMode == MODE_DEFAULT && _respawnForceEndGT <= 0.0 && _respawnSavedCell > 0
		_ApplyRespawnValues(_respawnSavedCell, _respawnSavedCleared)
		_respawnSavedCell = 0
		_respawnSavedCleared = 0
		Return
	EndIf
	_ApplyRespawnValues(GetRespawnActiveCell(), GetRespawnActiveCleared())
EndFunction

Function RespawnBeginTemporaryForce(Float hours)
	If hours <= 0.0
		hours = 2.0
	EndIf
	If _respawnMode == MODE_DEFAULT && _respawnForceEndGT <= 0.0
		_respawnSavedCell = Game.GetGameSettingInt("iHoursToRespawnCell")
		_respawnSavedCleared = Game.GetGameSettingInt("iHoursToRespawnCellCleared")
	EndIf
	_respawnForceEndGT = Utility.GetCurrentGameTime() + (hours / 24.0)
	RespawnApplyCurrent()
	RegisterForSingleUpdateGameTime(hours)
EndFunction

Function RespawnOnGameLoad()
	; Default mode with no window: leave the engine values (and other mods) alone
	If _respawnMode == MODE_DEFAULT && _respawnForceEndGT <= 0.0
		Return
	EndIf
	_RespawnTick()
EndFunction

Event OnUpdateGameTime()
	_RespawnTick()
EndEvent

Function _RespawnTick()
	If _respawnForceEndGT > 0.0
		Float now = Utility.GetCurrentGameTime()
		If now < _respawnForceEndGT
			Float remainingHours = (_respawnForceEndGT - now) * 24.0
			If remainingHours < 0.05
				remainingHours = 0.05
			EndIf
			RegisterForSingleUpdateGameTime(remainingHours)
		Else
			_respawnForceEndGT = 0.0
		EndIf
	EndIf
	RespawnApplyCurrent()
EndFunction

Function _ApplyRespawnValues(Int cellHours, Int clearedHours)
	If cellHours < 1
		cellHours = 1
	EndIf
	If clearedHours < 1
		clearedHours = 1
	EndIf
	ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCell " + cellHours)
	ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCellCleared " + clearedHours)
EndFunction