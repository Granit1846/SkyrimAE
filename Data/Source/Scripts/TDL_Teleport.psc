Scriptname TDL_Teleport extends Quest

; =====================================================
; TDL_Teleport
;
; Stages:
; 90 Ч Random City / Village
; 91 Ч Random Location + Message + GodBuff (20s)
; 92 Ч High Hrothgar
; 93 Ч Whiterun
; 94 Ч Solitude
; 95 Ч Windhelm
; 96 Ч Riften
; 97 Ч Markarth
; 98 Ч Falkreath
; 99 Ч Dawnstar
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

	;  –»“»„Ќќ: каст, а не AddSpell
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