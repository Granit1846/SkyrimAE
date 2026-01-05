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
		Utility.Wait(0.2)
		spawnedActor.StartCombat(PlayerRef)
		spawnedActor.EvaluatePackage()
		Return True
	EndIf

	If spawnedRef
		Return True
	EndIf

	_LogError("Spawn failed")
	Return False
EndFunction


; =====================================================
; INTERNAL
; =====================================================
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