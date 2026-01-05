Scriptname TDL_Blessing1 extends Quest

GlobalVariable Property TDL_DebugEnabled Auto

FormList Property TDL_Bles Auto
FormList Property TDL_Sign Auto

Spell Property TDL_GodBuff Auto


; =====================================================
; ENTRY
; =====================================================
Bool Function Run(Actor PlayerRef)
	If !PlayerRef
		_LogError("PlayerRef None")
		Return False
	EndIf

	Spell chosen = _PickSpellFromEither()
	If !chosen
		_LogError("Blessing lists empty or invalid")
		Return False
	EndIf

	chosen.Cast(PlayerRef, PlayerRef)

	If TDL_GodBuff
		TDL_GodBuff.Cast(PlayerRef, PlayerRef)
	EndIf

	Return True
EndFunction


; =====================================================
; PICK SPELL
; =====================================================
Spell Function _PickSpellFromEither()
	Int bSize = 0
	Int sSize = 0

	If TDL_Bles
		bSize = TDL_Bles.GetSize()
	EndIf
	If TDL_Sign
		sSize = TDL_Sign.GetSize()
	EndIf

	If bSize <= 0 && sSize <= 0
		Return None
	EndIf

	Bool useBless = true
	If bSize > 0 && sSize > 0
		useBless = (Utility.RandomInt(0, 1) == 0)
	ElseIf bSize <= 0
		useBless = false
	EndIf

	FormList listRef = None
	If useBless
		listRef = TDL_Bles
	Else
		listRef = TDL_Sign
	EndIf

	If !listRef || listRef.GetSize() <= 0
		Return None
	EndIf

	Int idx = Utility.RandomInt(0, listRef.GetSize() - 1)
	Form f = listRef.GetAt(idx)

	Return f as Spell
EndFunction


; =====================================================
; LOGGING
; =====================================================
Function _LogError(String msg)
	Debug.Trace("[TDL Blessing ERROR] " + msg)
	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL Blessing] ERROR: " + msg)
	EndIf
EndFunction