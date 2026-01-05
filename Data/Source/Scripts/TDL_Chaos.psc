; =========================
; TDL_Chaos.psc
; =========================
Scriptname TDL_Chaos extends Quest

ReferenceAlias Property PlayerAlias Auto

Bool Function RunStage(Int aiStage, Actor akPlayer)
	If !akPlayer
		akPlayer = Game.GetPlayer()
	EndIf
	If !akPlayer
		Debug.Trace("[TDL Chaos ERROR] Player is None")
		Return False
	EndIf

	TDL_ChaosAliasScript chaos = PlayerAlias as TDL_ChaosAliasScript
	If !chaos
		Debug.Trace("[TDL Chaos ERROR] PlayerAlias script not found")
		Return False
	EndIf

	If aiStage == 70
		chaos.StartLowG(akPlayer)
		Return True
	ElseIf aiStage == 71
		chaos.EnableBackfireTimed(akPlayer)
		Return True
	EndIf

	Debug.Trace("[TDL Chaos ERROR] Unhandled stage " + aiStage)
	Return False
EndFunction