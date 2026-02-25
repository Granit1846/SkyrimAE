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

; ---------- OPTIONAL: TDL_RespawningEncounterZones integration ----------
; Ёти свойства Ќ≈ об€зательны. ≈сли они не заполнены (None) Ч код ниже ничего не делает.
GlobalVariable Property TDL_Respawn_Mode Auto
GlobalVariable Property TDL_Respawn_iHoursToRespawnCell Auto
GlobalVariable Property TDL_Respawn_iHoursToRespawnCellCleared Auto


; =====================================================
; INTERNAL STATE (safety timer)
; =====================================================
Bool  _safetyActive = false
Float _safetyEndRT = 0.0

; =====================================================
; INTERNAL STATE (respawn force window)
; =====================================================
Int   _respawnPrevMode = 0
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

		; Force (2h) only if TDL_RespawningEncounterZones is wired via properties
		_RespawnPatch_BeginTemporaryForce(2.0)

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
; OPTIONAL: RESPAWN PATCH (Force window 2h, then restore previous mode)
; Active only if TDL_Respawn_Mode property is filled (not None)
; =====================================================
Bool Function _RespawnPatch_IsEnabled()
	If TDL_Respawn_Mode == None
		Return False
	EndIf
	Return True
EndFunction

Function _RespawnPatch_BeginTemporaryForce(Float hours)
	If !_RespawnPatch_IsEnabled()
		Return
	EndIf
	If hours <= 0.0
		hours = 2.0
	EndIf

	; если окно ещЄ не активно Ч запоминаем исходный режим
	If _respawnForceEndGT <= 0.0
		_respawnPrevMode = TDL_Respawn_Mode.GetValueInt()
	EndIf

	_respawnForceEndGT = Utility.GetCurrentGameTime() + (hours / 24.0)

	_RespawnPatch_ApplyForce()
	RegisterForSingleUpdateGameTime(hours)
EndFunction

Event OnPlayerLoadGame()
	_RespawnPatch_Tick()
EndEvent

Event OnUpdateGameTime()
	_RespawnPatch_Tick()
EndEvent

Function _RespawnPatch_Tick()
	If !_RespawnPatch_IsEnabled()
		Return
	EndIf
	If _respawnForceEndGT <= 0.0
		Return
	EndIf

	Float now = Utility.GetCurrentGameTime()
	If now < _respawnForceEndGT
		Float remainingHours = (_respawnForceEndGT - now) * 24.0
		If remainingHours < 0.05
			remainingHours = 0.05
		EndIf
		_RespawnPatch_ApplyForce()
		RegisterForSingleUpdateGameTime(remainingHours)
		Return
	EndIf

	_respawnForceEndGT = 0.0
	If _respawnPrevMode <= 0
		_respawnPrevMode = MODE_DEFAULT
	EndIf

	TDL_Respawn_Mode.SetValueInt(_respawnPrevMode)
	_RespawnPatch_ApplyMode(_respawnPrevMode)
EndFunction

Function _RespawnPatch_ApplyForce()
	TDL_Respawn_Mode.SetValueInt(MODE_FORCE)
	ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCell " + FORCE_CELL)
	ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCellCleared " + FORCE_CLEARED)
EndFunction

Function _RespawnPatch_ApplyMode(Int mode)
	If mode == MODE_DEFAULT
		ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCell " + DEFAULT_CELL)
		ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCellCleared " + DEFAULT_CLEARED)
		Return
	EndIf

	If mode == MODE_CUSTOM
		Int vCell = DEFAULT_CELL
		Int vCleared = DEFAULT_CLEARED

		If TDL_Respawn_iHoursToRespawnCell
			vCell = TDL_Respawn_iHoursToRespawnCell.GetValueInt()
		EndIf
		If TDL_Respawn_iHoursToRespawnCellCleared
			vCleared = TDL_Respawn_iHoursToRespawnCellCleared.GetValueInt()
		EndIf

		ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCell " + vCell)
		ConsoleUtil.ExecuteCommand("setgs iHoursToRespawnCellCleared " + vCleared)
		Return
	EndIf

	_RespawnPatch_ApplyForce()
EndFunction