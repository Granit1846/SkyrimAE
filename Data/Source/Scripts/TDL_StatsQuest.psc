Scriptname TDL_StatsQuest extends Quest

Int[] _stages
Int[] _counts
Int _size = 0

Function ResetSession()
	_stages = new Int[128]
	_counts = new Int[128]
	_size = 0
EndFunction

Function RecordStage(Int stage)
	If stage <= 0
		Return
	EndIf
	If _stages == None || _counts == None
		ResetSession()
	EndIf

	Int idx = _IndexOf(stage)
	If idx >= 0
		_counts[idx] = _counts[idx] + 1
		Return
	EndIf

	If _size >= 128
		Return
	EndIf

	_stages[_size] = stage
	_counts[_size] = 1
	_size = _size + 1
EndFunction

Int Function GetStageCount(Int stage)
	If _stages == None || _counts == None
		Return 0
	EndIf

	Int idx = _IndexOf(stage)
	If idx < 0
		Return 0
	EndIf
	Return _counts[idx]
EndFunction

Int Function _IndexOf(Int stage)
	Int i = 0
	While i < _size
		If _stages[i] == stage
			Return i
		EndIf
		i = i + 1
	EndWhile
	Return -1
EndFunction