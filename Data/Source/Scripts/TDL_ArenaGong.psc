Scriptname TDL_ArenaGong extends ObjectReference
TDL_Comedy Property Comedy Auto

Event OnActivate(ObjectReference akActionRef)
	If akActionRef == Game.GetPlayer() && Comedy
		Comedy.ArenaStartRequested()
	EndIf
EndEvent