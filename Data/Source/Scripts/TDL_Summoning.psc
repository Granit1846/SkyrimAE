Scriptname TDL_Summoning extends Quest

GlobalVariable Property TDL_DebugEnabled Auto

Static Property MarkerBase Auto ; XMarker

FormList Property TDL_Summon_Skeleton Auto
FormList Property TDL_Summon_Animal Auto
FormList Property TDL_Summon_Humanoid Auto
FormList Property TDL_Summon_Undead_and_Other Auto
FormList Property TDL_Summon_Strong Auto
FormList Property TDL_Summon_Dragon Auto

Float Property Radius = 250.0 Auto
Float Property ZOffset = 0.0 Auto
Float Property SummonLifetime = 300.0 Auto

Actor[] _summons
Float[] _summonEndRT
Float[] _summonRemainingRT
Float[] _summonDeadAtRT
Float _summonLastRT = 0.0
Int _summonCount = 0


; =====================================================
; LOGGING
; =====================================================
Function _LogError(String msg)
	Debug.Trace("[TDL Summoning ERROR] " + msg)
	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL Summoning] ERROR: " + msg)
	EndIf
EndFunction


; =====================================================
; PUBLIC API
; =====================================================
Bool Function RunAny(Actor PlayerRef)
	If !PlayerRef
		_LogError("PlayerRef None")
		Return False
	EndIf
	If !MarkerBase
		_LogError("MarkerBase not set")
		Return False
	EndIf

	Int tries = 0
	While tries < 30
		Int pick = Utility.RandomInt(1, 6)
		FormList l = _GetList(pick)
		If l && l.GetSize() > 0
			Return RunList(pick, PlayerRef)
		EndIf
		tries += 1
	EndWhile

	_LogError("All summon lists empty")
	Return False
EndFunction


Bool Function RunList(Int aiListIndex, Actor PlayerRef)
	If !PlayerRef
		_LogError("PlayerRef None")
		Return False
	EndIf
	If !MarkerBase
		_LogError("MarkerBase not set")
		Return False
	EndIf

	If aiListIndex >= 7
		aiListIndex = 6
	EndIf

	FormList listRef = _GetList(aiListIndex)
	If !listRef || listRef.GetSize() <= 0
		_LogError("Summon list " + aiListIndex + " empty")
		Return False
	EndIf

	_InitSummons()
	_CleanupSummons()
	If _summonCount >= 64
		_LogError("Summon tracking full")
		Return False
	EndIf

	ObjectReference marker = PlayerRef.PlaceAtMe(MarkerBase, 1)
	If !marker
		_LogError("Marker spawn failed")
		Return False
	EndIf

	Float dx = Utility.RandomFloat(-Radius, Radius)
	Float dy = Utility.RandomFloat(-Radius, Radius)
	marker.MoveTo(PlayerRef, dx, dy, ZOffset)

	Int idx = Utility.RandomInt(0, listRef.GetSize() - 1)
	Form f = listRef.GetAt(idx)
	ActorBase baseNPC = f as ActorBase

	If !baseNPC
		Debug.Trace("[TDL Summoning ERROR] List has non-ActorBase: " + f)
		marker.Disable()
		marker.Delete()
		Return False
	EndIf

	ObjectReference spawnedRef = marker.PlaceAtMe(baseNPC, 1)
	Actor spawnedActor = spawnedRef as Actor

	marker.Disable()
	marker.Delete()

	If spawnedActor
		_summons[_summonCount] = spawnedActor
		_summonEndRT[_summonCount] = Utility.GetCurrentRealTime() + SummonLifetime
		_summonRemainingRT[_summonCount] = SummonLifetime
		_summonDeadAtRT[_summonCount] = 0.0
		_summonCount += 1
		RegisterForSingleUpdate(5.0)
		Utility.Wait(0.2)
		spawnedActor.StartCombat(PlayerRef)
		spawnedActor.EvaluatePackage()
		Return True
	EndIf

	If spawnedRef
		spawnedRef.Disable()
		spawnedRef.Delete()
	EndIf

	_LogError("Spawn failed")
	Return False
EndFunction


; =====================================================
; INTERNAL
; =====================================================
Function _InitSummons()
	If !_summons
		_summons = new Actor[64]
		_summonEndRT = new Float[64]
		_summonRemainingRT = new Float[64]
		_summonLastRT = Utility.GetCurrentRealTime()
		_summonDeadAtRT = new Float[64]
	EndIf
EndFunction

Function _RemoveSummon(Int index)
	Actor a = _summons[index]
	If a
		a.Disable()
		a.Delete()
	EndIf
	Int i = index
	While i < _summonCount - 1
		_summons[i] = _summons[i + 1]
		_summonEndRT[i] = _summonEndRT[i + 1]
		_summonRemainingRT[i] = _summonRemainingRT[i + 1]
		_summonDeadAtRT[i] = _summonDeadAtRT[i + 1]
		i += 1
	EndWhile
	_summonCount -= 1
	_summons[_summonCount] = None
	_summonEndRT[_summonCount] = 0.0
	_summonRemainingRT[_summonCount] = 0.0
	_summonDeadAtRT[_summonCount] = 0.0
EndFunction

Function _CleanupSummons()
	Float now = Utility.GetCurrentRealTime()
	Float elapsed = now - _summonLastRT
	If elapsed < 0.0
		elapsed = 0.0
	EndIf
	_summonLastRT = now
	Int i = 0
	While i < _summonCount
		_summonRemainingRT[i] = _summonRemainingRT[i] - elapsed
		_summonEndRT[i] = now + _summonRemainingRT[i]
		i += 1
	EndWhile
	Int j = 0
	While j < _summonCount
		Actor a = _summons[j]
		If !a
			_RemoveSummon(j)
		ElseIf a.IsDead()
			If _summonDeadAtRT[j] <= 0.0
				_summonDeadAtRT[j] = now + 20.0
			EndIf
			If now >= _summonDeadAtRT[j]
				_RemoveSummon(j)
			Else
				j += 1
			EndIf
		ElseIf now >= _summonEndRT[j] && !a.IsInCombat()
			_RemoveSummon(j)
		Else
			j += 1
		EndIf
	EndWhile
EndFunction

Event OnUpdate()
	_CleanupSummons()
	If _summonCount > 0
		RegisterForSingleUpdate(5.0)
	EndIf
EndEvent

Function EndTransientOnLoad()
	_InitSummons()
	Float now = Utility.GetCurrentRealTime()
	Int i = 0
	While i < _summonCount
		_summonEndRT[i] = now + _summonRemainingRT[i]
		If _summonDeadAtRT[i] > 0.0
			Float remaining = _summonDeadAtRT[i] - _summonLastRT
			If remaining < 0.0
				remaining = 0.0
			ElseIf remaining > 20.0
				remaining = 20.0
			EndIf
			_summonDeadAtRT[i] = now + remaining
		EndIf
		i += 1
	EndWhile
	_summonLastRT = now
	If _summonCount > 0
		RegisterForSingleUpdate(5.0)
	EndIf
EndFunction

FormList Function _GetList(Int aiListIndex)
	If aiListIndex == 1
		Return TDL_Summon_Skeleton
	ElseIf aiListIndex == 2
		Return TDL_Summon_Animal
	ElseIf aiListIndex == 3
		Return TDL_Summon_Humanoid
	ElseIf aiListIndex == 4
		Return TDL_Summon_Undead_and_Other
	ElseIf aiListIndex == 5
		Return TDL_Summon_Strong
	EndIf
	Return TDL_Summon_Dragon
EndFunction