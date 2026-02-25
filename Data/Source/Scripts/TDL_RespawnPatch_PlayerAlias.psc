ScriptName TDL_RespawnPatch_PlayerAlias extends ReferenceAlias

TDL_RespawnPatchController Property Controller Auto

Event OnInit()
	_RegisterFastTravelEvents()
EndEvent

Event OnPlayerLoadGame()
	_RegisterFastTravelEvents()
EndEvent

Function _RegisterFastTravelEvents()
	PO3_Events_Alias.RegisterForFastTravelConfirmed(Self)
	PO3_Events_Alias.RegisterForOnPlayerFastTravelEnd(Self)
EndFunction

Event OnFastTravelConfirmed(ObjectReference asMarkerReference)
	If Controller
		Controller.BeginTemporaryForce(2.0)
	EndIf
EndEvent

Event OnPlayerFastTravelEnd(float afTravelGameTimeHours)
	If Controller
		Controller.BeginTemporaryForce(2.0)
	EndIf
EndEvent