Scriptname TDL_Healing extends Quest

GlobalVariable Property TDL_DebugEnabled Auto

Spell Property GrandHealing Auto
Spell Property Dragonhide Auto


; =====================================================
; ENTRY
; =====================================================
Bool Function Run(Actor PlayerRef)
	If !PlayerRef
		_LogError("PlayerRef None")
		Return False
	EndIf

	If !GrandHealing
		GrandHealing = Game.GetFormFromFile(0x000B62EE, "Skyrim.esm") as Spell
	EndIf
	If !Dragonhide
		Dragonhide = Game.GetFormFromFile(0x000CDB70, "Skyrim.esm") as Spell
	EndIf

	If !GrandHealing || !Dragonhide
		_LogError("Healing spells missing")
		Return False
	EndIf

	GrandHealing.Cast(PlayerRef, PlayerRef)
	Dragonhide.Cast(PlayerRef, PlayerRef)

	Return True
EndFunction


; =====================================================
; LOGGING
; =====================================================
Function _LogError(String msg)
	Debug.Trace("[TDL Healing ERROR] " + msg)
	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL Healing] ERROR: " + msg)
	EndIf
EndFunction