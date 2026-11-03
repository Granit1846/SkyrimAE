Scriptname TDL_ArenaChest extends ObjectReference
TDL_Comedy Property Comedy Auto

Event OnClose(ObjectReference akActionRef)
	If akActionRef == Game.GetPlayer() && Comedy
		Comedy.ArenaChestClosed()
	EndIf
EndEvent