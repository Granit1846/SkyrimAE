ScriptName TDL_RespawnPatch_TDLCompat extends Quest

Quest Property MainControllerQuest Auto
TDL_RespawnPatchController Property RespawnController Auto

Int STAGE_TELEPORT_91 = 91
Bool _fired = False

Event OnInit()
	RegisterForSingleUpdate(1.0)
EndEvent

Event OnPlayerLoadGame()
	RegisterForSingleUpdate(1.0)
EndEvent

Event OnUpdate()
	If _fired
		Return
	EndIf

	If MainControllerQuest && MainControllerQuest.IsStageDone(STAGE_TELEPORT_91)
		_fired = True
		If RespawnController
			RespawnController.BeginTemporaryForce(2.0)
		EndIf
		Return
	EndIf

	RegisterForSingleUpdate(1.0)
EndEvent