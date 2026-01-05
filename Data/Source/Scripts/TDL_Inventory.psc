Scriptname TDL_Inventory extends Quest

; =========================
; PROPERTIES (CK)
; =========================
GlobalVariable Property TDL_DebugEnabled Auto

FormList Property InvSpamList Auto
Static Property ScatterMarker Auto
GlobalVariable Property InvSpam_RollsGV Auto
GlobalVariable Property InvSpam_CountMinGV Auto
GlobalVariable Property InvSpam_CountMaxGV Auto
GlobalVariable Property InvSpam_RadiusGV Auto

Container Property InvHolderContainerBase Auto
GlobalVariable Property InvDrop_BatchSizeGV Auto
GlobalVariable Property InvDrop_IntervalGV Auto

FormList Property InvProtectedForms Auto
GlobalVariable Property InvProtectTokensByNameGV Auto

GlobalVariable Property InvDrop_ShowProgressGV Auto
GlobalVariable Property InvDrop_TimeoutGV Auto

; =========================
; INTERNAL STATE
; =========================
ObjectReference _holderRef
Bool _dropActive = false

Int _dropBatch = 10
Float _dropInterval = 0.20

Int _totalItems = 0
Int _processedItems = 0
Float _dropStartTime = 0.0
Bool _showProgress = false


; =========================
; LOGGING
; =========================
Function _LogError(String msg)
	Debug.Trace("[TDL Inventory ERROR] " + msg)
	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL Inventory] ERROR: " + msg)
	EndIf
EndFunction

Function _LogInfo(String msg)
	Debug.Trace("[TDL Inventory] " + msg)
EndFunction


; =========================
; ENTRY POINT
; =========================
Bool Function RunStage(Int aiStage, Actor playerRef)
	If aiStage == 80
		ScatterOneItemType(playerRef)
		Return True
	ElseIf aiStage == 81
		DropAllItems(playerRef)
		Return True
	EndIf

	_LogError("Unknown stage " + aiStage)
	Return False
EndFunction


; =========================
; STAGE 80 — SCATTER
; =========================
Function ScatterOneItemType(Actor PlayerRef)
	If !PlayerRef
		_LogError("PlayerRef None")
		Return
	EndIf
	If !InvSpamList || InvSpamList.GetSize() <= 0
		_LogError("InvSpamList empty")
		Return
	EndIf
	If !ScatterMarker
		_LogError("ScatterMarker not set")
		Return
	EndIf

	Float Radius = 800.0
	If InvSpam_RadiusGV
		Radius = InvSpam_RadiusGV.GetValue()
	EndIf
	If Radius < 100.0
		Radius = 100.0
	EndIf

	Int MinCount = 150
	If InvSpam_CountMinGV
		MinCount = InvSpam_CountMinGV.GetValueInt()
	EndIf

	Int MaxCount = 200
	If InvSpam_CountMaxGV
		MaxCount = InvSpam_CountMaxGV.GetValueInt()
	EndIf
	If MinCount < 1
		MinCount = 1
	EndIf
	If MaxCount < MinCount
		MaxCount = MinCount
	EndIf

	Int total = Utility.RandomInt(MinCount, MaxCount)

	Int pick = Utility.RandomInt(0, InvSpamList.GetSize() - 1)
	Form itemForm = InvSpamList.GetAt(pick)
	If !itemForm
		_LogError("Picked item None")
		Return
	EndIf

	Int i = 0
	While i < total
		Float dx = Utility.RandomFloat(-Radius, Radius)
		Float dy = Utility.RandomFloat(-Radius, Radius)

		If (dx * dx + dy * dy) <= (Radius * Radius)
			ObjectReference marker = PlayerRef.PlaceAtMe(ScatterMarker, 1, false, true)
			If marker
				marker.MoveTo(PlayerRef, dx, dy, 10.0, true)
				marker.PlaceAtMe(itemForm, 1)
				marker.Disable(true)
				marker.Delete()
			EndIf
			i += 1
		EndIf
	EndWhile
EndFunction


; =========================
; STAGE 81 — DROP ALL (SAFE)
; =========================
Function DropAllItems(Actor playerRef)

	If _dropActive
		_LogInfo("DropAllItems already running")
		Return
	EndIf

	If !playerRef
		_LogError("PlayerRef None")
		Return
	EndIf

	If !InvHolderContainerBase
		_LogError("InvHolderContainerBase not set")
		Return
	EndIf

	_dropBatch = 10
	If InvDrop_BatchSizeGV
		_dropBatch = InvDrop_BatchSizeGV.GetValueInt()
	EndIf
	If _dropBatch < 1
		_dropBatch = 1
	EndIf

	_dropInterval = 0.20
	If InvDrop_IntervalGV
		_dropInterval = InvDrop_IntervalGV.GetValue()
	EndIf
	If _dropInterval < 0.05
		_dropInterval = 0.05
	EndIf

	_showProgress = false
	If InvDrop_ShowProgressGV
		_showProgress = (InvDrop_ShowProgressGV.GetValueInt() == 1)
	EndIf

	_holderRef = playerRef.PlaceAtMe(InvHolderContainerBase, 1, false, false)
	If !_holderRef
		_LogError("Failed to create holder container")
		Return
	EndIf

	_holderRef.BlockActivation(true)
	playerRef.RemoveAllItems(_holderRef, true, false)

	_totalItems = _holderRef.GetNumItems()
	_processedItems = 0
	_dropStartTime = Utility.GetCurrentRealTime()
	_dropActive = true

	RegisterForSingleUpdate(0.1)
EndFunction


; =========================
; UPDATE LOOP
; =========================
Event OnUpdate()
	If !_dropActive
		Return
	EndIf

	Float timeout = 30.0
	If InvDrop_TimeoutGV
		timeout = InvDrop_TimeoutGV.GetValue()
	EndIf

	If (Utility.GetCurrentRealTime() - _dropStartTime) > timeout
		_LogError("DropAllItems timeout")
		_FinishDrop(false)
		Return
	EndIf

	Actor p = Game.GetPlayer()
	If !_holderRef || !p
		_LogError("Holder or player missing")
		_FinishDrop(false)
		Return
	EndIf

	_holderRef.MoveTo(p)

	Int processed = 0
	Int safety = 0

	While processed < _dropBatch && safety < (_dropBatch * 2)
		safety += 1

		If _holderRef.GetNumItems() <= 0
			_FinishDrop(true)
			Return
		EndIf

		Form item = _holderRef.GetNthForm(0)
		If !item
			processed += 1
			_processedItems += 1
		Else
			Int count = _holderRef.GetItemCount(item)
			If count <= 0
				_holderRef.RemoveItem(item, 1, true, None)
			Else
				If _IsItemProtected(item)
					_holderRef.RemoveItem(item, count, true, p)
				Else
					_holderRef.DropObject(item, count)
				EndIf
			EndIf

			processed += 1
			_processedItems += 1

			If _showProgress && (_processedItems % 50 == 0)
				Int pct = (_processedItems * 100) / _totalItems
				Debug.Notification("TDL: Drop " + pct + "%")
			EndIf
		EndIf
	EndWhile

	RegisterForSingleUpdate(_dropInterval)
EndEvent


; =========================
; PROTECTION
; =========================
Bool Function _IsItemProtected(Form item)
	If item as Key
		Return True
	EndIf

	If InvProtectedForms && InvProtectedForms.HasForm(item)
		Return True
	EndIf

	If InvProtectTokensByNameGV == None || InvProtectTokensByNameGV.GetValueInt() == 1
		Return _IsTokenByName(item)
	EndIf

	Return False
EndFunction

Bool Function _IsTokenByName(Form item)
	String nm = item.GetName()
	If nm == ""
		Return True
	EndIf

	If StringUtil.Find(nm, "token") != -1 || StringUtil.Find(nm, "Token") != -1 || StringUtil.Find(nm, "TOKEN") != -1
		Return True
	EndIf
	If StringUtil.Find(nm, "òîêåí") != -1 || StringUtil.Find(nm, "Òîêåí") != -1 || StringUtil.Find(nm, "ÒÎÊÅÍ") != -1
		Return True
	EndIf
	If StringUtil.Find(nm, "æåòîí") != -1 || StringUtil.Find(nm, "Æåòîí") != -1 || StringUtil.Find(nm, "ÆÅÒÎÍ") != -1
		Return True
	EndIf

	Return False
EndFunction


; =========================
; FINISH
; =========================
Function _FinishDrop(Bool success)
	_dropActive = false

	If _holderRef
		If _holderRef.IsEnabled()
			_holderRef.Disable(true)
		EndIf
		_holderRef.Delete()
		_holderRef = None
	EndIf

	_totalItems = 0
	_processedItems = 0
	_dropStartTime = 0.0
EndFunction