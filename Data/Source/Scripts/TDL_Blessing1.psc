Scriptname TDL_Blessing1 extends Quest

GlobalVariable Property TDL_DebugEnabled Auto

FormList Property TDL_Bles Auto
FormList Property TDL_Sign Auto

Spell Property TDL_GodBuff Auto

; internal: what group was picked in _PickSpellFromEither()
Bool _lastPickWasBless = true

Bool Function Run(Actor PlayerRef)
	If !PlayerRef
		PlayerRef = Game.GetPlayer()
	EndIf
	If !PlayerRef
		_Notify("TDL Bless PlayerRef None")
		Return False
	EndIf

	; 1) always cast GodBuff (separate from bless/sign logic)
	If TDL_GodBuff
		TDL_GodBuff.Cast(PlayerRef, PlayerRef)
	EndIf

	; 2) pick from Bless or Sign
	Spell chosen = _PickSpellFromEither()
	If !chosen
		_Notify("TDL Bless lists empty or non-spell")
		Return False
	EndIf

	; 3) apply with vanilla-safe overwrite rules
	If _lastPickWasBless
		; Blessings: overwrite Blessings only (dispel), then cast chosen
		_DispelListSpells(PlayerRef, TDL_Bles)
		chosen.Cast(PlayerRef, PlayerRef)
		_Notify("TDL Bless OK (Bless): " + chosen.GetName())
		Return True
	Else
		; Signs: overwrite Signs only (remove), then add chosen ability
		_RemoveListSpells(PlayerRef, TDL_Sign)

		; force refresh even if same sign re-rolled
		If PlayerRef.HasSpell(chosen)
			PlayerRef.RemoveSpell(chosen)
		EndIf
		PlayerRef.AddSpell(chosen, false)

		_Notify("TDL Bless OK (Sign): " + chosen.GetName())
		Return True
	EndIf
EndFunction

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

	Bool useBless = True
	If bSize > 0 && sSize > 0
		If Utility.RandomInt(0, 1) == 0
			useBless = True
		Else
			useBless = False
		EndIf
	ElseIf bSize <= 0
		useBless = False
	Else
		useBless = True
	EndIf

	_lastPickWasBless = useBless

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

Function _DispelListSpells(Actor p, FormList lst)
	If !p || !lst
		Return
	EndIf

	Int i = 0
	Int sz = lst.GetSize()
	While i < sz
		Spell sp = lst.GetAt(i) as Spell
		If sp
			p.DispelSpell(sp)
		EndIf
		i += 1
	EndWhile
EndFunction

Function _RemoveListSpells(Actor p, FormList lst)
	If !p || !lst
		Return
	EndIf

	Int i = 0
	Int sz = lst.GetSize()
	While i < sz
		Spell sp = lst.GetAt(i) as Spell
		If sp && p.HasSpell(sp)
			p.RemoveSpell(sp)
		EndIf
		i += 1
	EndWhile
EndFunction

Function _Notify(String asText)
	If !TDL_DebugEnabled || (TDL_DebugEnabled.GetValueInt() == 1)
		Debug.Notification(asText)
	EndIf
EndFunction