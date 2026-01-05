Scriptname TDL_Hunter extends Quest

; =========================
; PROPERTIES (CK)
; =========================
FormList Property ListOfHunters Auto
ObjectReference Property SpawnMarker Auto
GlobalVariable Property HunterDuration Auto
GlobalVariable Property ReAggroInterval Auto
GlobalVariable Property MaxDistance Auto
GlobalVariable Property SpawnOffset Auto
GlobalVariable Property HunterCorpseLifetime Auto
Int Property AILevelMod = 3 Auto

; =========================
; DEBUG
; =========================
GlobalVariable Property TDL_DebugEnabled Auto

; =========================
; INTERNAL STATE
; =========================
Actor _hunter
Bool _active = false
Float _remaining = 0.0

Bool _dead = false
Float _removeCorpseAt = 0.0


; =========================
; LOGGING
; =========================
Function _LogError(String msg)
	Debug.Trace("[TDL Hunter ERROR] " + msg)
	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL Hunter] ERROR: " + msg)
	EndIf
EndFunction


; =========================
; PUBLIC API
; =========================
Function StartHunter()
	Actor p = Game.GetPlayer()
	If !p
		_LogError("Player None")
		Return
	EndIf

	ActorBase picked = _PickRandomHunterBase()
	If !picked
		_LogError("Hunter list empty or invalid")
		Return
	EndIf

	Float dur = 90.0
	If HunterDuration
		dur = HunterDuration.GetValue()
	EndIf
	If dur < 5.0
		dur = 5.0
	EndIf

	; refresh only
	If _active && _hunter
		_remaining = dur
		_ForceAggro()
		_hunter.EvaluatePackage()
		RegisterForSingleUpdate(0.5)
		Return
	EndIf

	Cleanup()

	ObjectReference src = SpawnMarker
	If !src
		src = p
	EndIf

	_hunter = src.PlaceActorAtMe(picked, AILevelMod)
	If !_hunter
		_LogError("Spawn failed")
		Return
	EndIf

	_PositionHunterNearPlayer(p)

	_remaining = dur
	_active = true

	_ForceAggro()
	_hunter.EvaluatePackage()

	RegisterForSingleUpdate(0.5)
EndFunction


Function StopHunter()
	Cleanup()
EndFunction


; =========================
; INTERNAL LOGIC
; =========================
ActorBase Function _PickRandomHunterBase()
	If !ListOfHunters || ListOfHunters.GetSize() <= 0
		Return None
	EndIf

	Int sz = ListOfHunters.GetSize()
	Int tries = 0
	While tries < 10
		Int idx = Utility.RandomInt(0, sz - 1)
		ActorBase ab = ListOfHunters.GetAt(idx) as ActorBase
		If ab
			Return ab
		EndIf
		tries += 1
	EndWhile

	Int i = 0
	While i < sz
		ActorBase ab2 = ListOfHunters.GetAt(i) as ActorBase
		If ab2
			Return ab2
		EndIf
		i += 1
	EndWhile

	Return None
EndFunction


Function _PositionHunterNearPlayer(Actor p)
	If !_hunter || !p
		Return
	EndIf

	Float off = 1200.0
	If SpawnOffset
		off = SpawnOffset.GetValue()
	EndIf
	If off < 300.0
		off = 300.0
	EndIf

	Int r = Utility.RandomInt(0, 3)
	If r == 0
		_hunter.MoveTo(p, off, 0.0, 0.0, true)
	ElseIf r == 1
		_hunter.MoveTo(p, -off, 0.0, 0.0, true)
	ElseIf r == 2
		_hunter.MoveTo(p, 0.0, off, 0.0, true)
	Else
		_hunter.MoveTo(p, 0.0, -off, 0.0, true)
	EndIf
EndFunction


Function _ForceAggro()
	Actor p = Game.GetPlayer()
	If !p || !_hunter
		Return
	EndIf
	If _hunter.IsDead()
		Return
	EndIf

	_hunter.StartCombat(p)
EndFunction


; =========================
; UPDATE LOOP
; =========================
Event OnUpdate()
	If !_active
		Return
	EndIf

	Actor p = Game.GetPlayer()
	If !p || !_hunter
		Cleanup()
		Return
	EndIf

	; === DEATH ===
	If _hunter.IsDead()
		If !_dead
			_dead = true

			Float delay = 20.0
			If HunterCorpseLifetime
				delay = HunterCorpseLifetime.GetValue()
			EndIf
			If delay < 0.0
				delay = 0.0
			EndIf

			_removeCorpseAt = Utility.GetCurrentRealTime() + delay
		EndIf

		If Utility.GetCurrentRealTime() >= _removeCorpseAt
			Cleanup()
			Return
		EndIf

		RegisterForSingleUpdate(1.0)
		Return
	EndIf

	; === ACTIVE CHASE ===
	Float iv = 4.0
	If ReAggroInterval
		iv = ReAggroInterval.GetValue()
	EndIf
	If iv < 1.0
		iv = 1.0
	ElseIf iv > 10.0
		iv = 10.0
	EndIf

	Float maxD = 5500.0
	If MaxDistance
		maxD = MaxDistance.GetValue()
	EndIf
	If maxD < 1500.0
		maxD = 1500.0
	EndIf

	If _hunter.GetParentCell() != p.GetParentCell() || _hunter.GetDistance(p) > maxD
		_PositionHunterNearPlayer(p)
	EndIf

	_ForceAggro()
	_hunter.EvaluatePackage()

	_remaining -= iv
	If _remaining <= 0.0
		Cleanup()
		Return
	EndIf

	RegisterForSingleUpdate(iv)
EndEvent


; =========================
; CLEANUP
; =========================
Function Cleanup()
	_active = false
	_remaining = 0.0
	_dead = false
	_removeCorpseAt = 0.0

	If _hunter
		_hunter.Disable()
		_hunter.Delete()
		_hunter = None
	EndIf
EndFunction