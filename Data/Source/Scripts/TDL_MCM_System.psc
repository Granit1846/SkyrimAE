ScriptName TDL_MCM_System extends Quest

Quest Property MainControllerQuest Auto

; =========================
; OIDs — LEFT COLUMN
; =========================
Int OID_Healing        = -1

Int OID_WeatherClear  = -1
Int OID_WeatherRain   = -1
Int OID_WeatherSnow   = -1
Int OID_WeatherStorm  = -1
Int OID_WeatherFog    = -1
Int OID_WeatherReset  = -1

; =========================
; OIDs — RIGHT COLUMN
; =========================
Int OID_Blessing = -1

Int OID_SummonAny       = -1
Int OID_SummonSkeleton = -1
Int OID_SummonAnimal   = -1
Int OID_SummonHumanoid = -1
Int OID_SummonUndead   = -1
Int OID_SummonStrong   = -1
Int OID_SummonDragon   = -1

; =====================================================
; BUILD PAGE
; =====================================================
Function BuildPage(SKI_ConfigBase mcm)

	; === GLOBAL LAYOUT RULE ===
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	; =================================================
	; LEFT COLUMN — HEALING + WEATHER
	; =================================================
	mcm.SetCursorPosition(0)

	; ----- HEALING -----
	mcm.AddHeaderOption("$SystemHeaderHealing")
	OID_Healing = mcm.AddTextOption("$SystemHealing", "$ActionActivate")

	mcm.AddEmptyOption()

	; ----- WEATHER -----
	mcm.AddHeaderOption("$SystemHeaderWeather")
	OID_WeatherClear = mcm.AddTextOption("$WeatherClear", "$ActionActivate")
	OID_WeatherRain  = mcm.AddTextOption("$WeatherRain", "$ActionActivate")
	OID_WeatherSnow  = mcm.AddTextOption("$WeatherSnow", "$ActionActivate")
	OID_WeatherStorm = mcm.AddTextOption("$WeatherStorm", "$ActionActivate")
	OID_WeatherFog   = mcm.AddTextOption("$WeatherFog", "$ActionActivate")

	mcm.AddEmptyOption()
	OID_WeatherReset = mcm.AddTextOption("$WeatherReset", "$ActionReset")

	; =================================================
	; RIGHT COLUMN — BLESSING + SUMMONING
	; =================================================
	mcm.SetCursorPosition(1)

	; ----- BLESSING -----
	mcm.AddHeaderOption("$SystemHeaderBlessing")
	OID_Blessing = mcm.AddTextOption("$SystemBlessing", "$ActionActivate")

	mcm.AddEmptyOption()

	; ----- SUMMONING -----
	mcm.AddHeaderOption("$SystemHeaderSummon")
	OID_SummonAny       = mcm.AddTextOption("$SystemSummonAny", "$ActionActivate")
	OID_SummonSkeleton = mcm.AddTextOption("$SystemSummonSkeleton", "$ActionActivate")
	OID_SummonAnimal   = mcm.AddTextOption("$SystemSummonAnimal", "$ActionActivate")
	OID_SummonHumanoid = mcm.AddTextOption("$SystemSummonHumanoid", "$ActionActivate")
	OID_SummonUndead   = mcm.AddTextOption("$SystemSummonUndead", "$ActionActivate")
	OID_SummonStrong   = mcm.AddTextOption("$SystemSummonStrong", "$ActionActivate")
	OID_SummonDragon   = mcm.AddTextOption("$SystemSummonDragon", "$ActionActivate")

EndFunction

; =====================================================
; OPTION SELECT
; =====================================================
Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)

	If MainControllerQuest == None
		Return False
	EndIf

	; ===== HEALING =====
	If option == OID_Healing
		MainControllerQuest.SetStage(20)
		Return True
	EndIf

	; ===== WEATHER =====
	If option == OID_WeatherClear
		MainControllerQuest.SetStage(110)
		Return True
	EndIf
	If option == OID_WeatherRain
		MainControllerQuest.SetStage(111)
		Return True
	EndIf
	If option == OID_WeatherSnow
		MainControllerQuest.SetStage(112)
		Return True
	EndIf
	If option == OID_WeatherStorm
		MainControllerQuest.SetStage(113)
		Return True
	EndIf
	If option == OID_WeatherFog
		MainControllerQuest.SetStage(114)
		Return True
	EndIf
	If option == OID_WeatherReset
		MainControllerQuest.SetStage(119)
		Return True
	EndIf

	; ===== BLESSING =====
	If option == OID_Blessing
		MainControllerQuest.SetStage(30)
		Return True
	EndIf

	; ===== SUMMONING =====
	If option == OID_SummonAny
		MainControllerQuest.SetStage(40)
		Return True
	EndIf
	If option == OID_SummonSkeleton
		MainControllerQuest.SetStage(41)
		Return True
	EndIf
	If option == OID_SummonAnimal
		MainControllerQuest.SetStage(42)
		Return True
	EndIf
	If option == OID_SummonHumanoid
		MainControllerQuest.SetStage(43)
		Return True
	EndIf
	If option == OID_SummonUndead
		MainControllerQuest.SetStage(44)
		Return True
	EndIf
	If option == OID_SummonStrong
		MainControllerQuest.SetStage(45)
		Return True
	EndIf
	If option == OID_SummonDragon
		MainControllerQuest.SetStage(46)
		Return True
	EndIf

	Return False
EndFunction