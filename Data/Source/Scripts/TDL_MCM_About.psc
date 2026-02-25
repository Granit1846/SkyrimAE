ScriptName TDL_MCM_About extends SKI_ConfigBase

Spell Property TDL_MenuAbility Auto

Int OID_QMStatus = -1
Int OID_QMAdd = -1
Int OID_QMRemove = -1
Int OID_QMReset = -1

Function BuildPage(SKI_ConfigBase mcm)
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$TDLAboutHeader")
	mcm.AddTextOption("$TDLAboutModVersion", "1.0.2")
	mcm.AddTextOption("$TDLAboutMCMVersion", "27")
	mcm.AddTextOption("$TDLAboutActiveFunctions", "45")
	mcm.AddTextOption("$TDLAboutAuthor", "Skeorz")

	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$TDLAboutQuickMenuHeader")
	OID_QMStatus = mcm.AddTextOption("$TDLAboutQuickMenuStatus", GetQuickMenuStatus())
	OID_QMAdd = mcm.AddTextOption("$TDLAboutQuickMenuAdd", "$ActionAdd")
	OID_QMRemove = mcm.AddTextOption("$TDLAboutQuickMenuRemove", "$ActionRemove")
	OID_QMReset = mcm.AddTextOption("$TDLAboutResetModule", "$ActionReset")
EndFunction

Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)
	Actor p = Game.GetPlayer()
	If p == None
		Return False
	EndIf

	If option == OID_QMAdd
		SetQuickMenu(p, true)
		UpdateStatus(mcm)
		Return True
	EndIf

	If option == OID_QMRemove
		SetQuickMenu(p, false)
		UpdateStatus(mcm)
		Return True
	EndIf

	If option == OID_QMReset
		SetQuickMenu(p, true)
		UpdateStatus(mcm)
		Return True
	EndIf

	Return False
EndFunction

Function UpdateStatus(SKI_ConfigBase mcm)
	If OID_QMStatus > -1
		mcm.SetTextOptionValue(OID_QMStatus, GetQuickMenuStatus())
	EndIf
EndFunction

String Function GetQuickMenuStatus()
	Actor p = Game.GetPlayer()
	If p == None || TDL_MenuAbility == None
		Return "$StatusUnknown"
	EndIf
	If p.HasSpell(TDL_MenuAbility)
		Return "$StatusEnabled"
	EndIf
	Return "$StatusDisabled"
EndFunction

Function SetQuickMenu(Actor p, Bool enableIt)
	If TDL_MenuAbility == None
		Return
	EndIf

	If enableIt
		If !p.HasSpell(TDL_MenuAbility)
			p.AddSpell(TDL_MenuAbility, false)
		EndIf
	Else
		If p.HasSpell(TDL_MenuAbility)
			p.RemoveSpell(TDL_MenuAbility)
		EndIf
	EndIf
EndFunction