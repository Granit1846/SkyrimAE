Scriptname TDL_MainController extends Quest

GlobalVariable Property TDL_DebugEnabled Auto
GlobalVariable Property TDL_LastErrorCode Auto


; =====================================================
; ENTRY POINT
; =====================================================
Bool Function RunStage(Int aiStage)

	Actor playerRef = Game.GetPlayer()
	If !playerRef
		Return _Fail(aiStage, 10, "PlayerRef None")
	EndIf

	Quest q = Self as Quest

	; ===== SYSTEM =====
	If aiStage == 1
		Return True
	ElseIf aiStage == 10
		Return True

	; ===== WRATH (11–13) =====
	ElseIf aiStage == 11 || aiStage == 12 || aiStage == 13
		TDL_WrathOfGod wrath = q as TDL_WrathOfGod
		If !wrath
			Return _Fail(aiStage, 20, "No TDL_WrathOfGod on quest")
		EndIf
		Return wrath.RunStage(aiStage, playerRef)

	; ===== HEALING =====
	ElseIf aiStage == 20
		TDL_Healing heal = q as TDL_Healing
		If !heal
			Return _Fail(aiStage, 30, "No TDL_Healing on quest")
		EndIf
		Return heal.Run(playerRef)

	; ===== BLESSING =====
	ElseIf aiStage == 30
		TDL_Blessing1 bless = q as TDL_Blessing1
		If !bless
			Return _Fail(aiStage, 40, "No TDL_Blessing1 on quest")
		EndIf
		Return bless.Run(playerRef)

	; ===== SUMMONING =====
	ElseIf aiStage == 40
		TDL_Summoning sumAny = q as TDL_Summoning
		If !sumAny
			Return _Fail(aiStage, 50, "No TDL_Summoning on quest")
		EndIf
		Return sumAny.RunAny(playerRef)

	ElseIf aiStage >= 41 && aiStage <= 46
		TDL_Summoning sum = q as TDL_Summoning
		If !sum
			Return _Fail(aiStage, 50, "No TDL_Summoning on quest")
		EndIf
		Return sum.RunList(aiStage - 40, playerRef)

	; ===== HUNTER =====
	ElseIf aiStage == 47
		TDL_Hunter hunter = q as TDL_Hunter
		If !hunter
			Return _Fail(aiStage, 60, "No TDL_Hunter on quest")
		EndIf
		hunter.StartHunter()
		Return True

	; ===== COMEDY (50–53) =====
	ElseIf aiStage >= 50 && aiStage <= 53
		TDL_Comedy comedy = q as TDL_Comedy
		If !comedy
			Return _Fail(aiStage, 65, "No TDL_Comedy on quest")
		EndIf
		Return comedy.RunStage(aiStage, playerRef)

	; ===== CHAOS (70–71) =====
	ElseIf aiStage == 70 || aiStage == 71
		TDL_Chaos chaos = q as TDL_Chaos
		If !chaos
			Return _Fail(aiStage, 70, "No TDL_Chaos on quest")
		EndIf
		Return chaos.RunStage(aiStage, playerRef)

	; ===== INVENTORY (80–81) =====
	ElseIf aiStage == 80 || aiStage == 81
		TDL_Inventory inv = q as TDL_Inventory
		If !inv
			Return _Fail(aiStage, 80, "No TDL_Inventory on quest")
		EndIf
		Return inv.RunStage(aiStage, playerRef)

	; ===== TELEPORT (90–99) =====
	ElseIf aiStage >= 90 && aiStage <= 99
		TDL_Teleport tp = q as TDL_Teleport
		If !tp
 			Return _Fail(aiStage, 90, "No TDL_Teleport on quest")
 		EndIf
 		Return tp.RunStage(aiStage, playerRef)

	; ===== VIRUS (100–103) =====
	ElseIf aiStage >= 100 && aiStage <= 103
		TDL_Virus virus = q as TDL_Virus
		If !virus
			Return _Fail(aiStage, 100, "No TDL_Virus on quest")
		EndIf
		Return virus.RunStage(aiStage, playerRef)

	; ===== WEATHER (110–119) =====
	ElseIf aiStage >= 110 && aiStage <= 119
		TDL_Weather wthr = q as TDL_Weather
		If !wthr
			Return _Fail(aiStage, 110, "No TDL_Weather on quest")
		EndIf
		Return wthr.RunStage(aiStage, playerRef)

	; ===== GIGANT (120–124) =====
	ElseIf aiStage >= 120 && aiStage <= 124
		TDL_Gigant gig = q as TDL_Gigant
		If !gig
			Return _Fail(aiStage, 120, "No TDL_Gigant on quest")
		EndIf
		Return gig.RunStage(aiStage, playerRef)

	EndIf

	Return _Fail(aiStage, 1, "Unhandled stage")
EndFunction


; =====================================================
; ERROR HANDLING
; =====================================================
Bool Function _Fail(Int aiStage, Int aiCode, String asMsg)

	If TDL_LastErrorCode
		TDL_LastErrorCode.SetValue(aiCode as Float)
	EndIf

	Debug.Trace("[TDL ERROR] stage=" + aiStage + " code=" + aiCode + " msg=" + asMsg)

	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL] ERROR stage " + aiStage)
	EndIf

	Return False
EndFunction