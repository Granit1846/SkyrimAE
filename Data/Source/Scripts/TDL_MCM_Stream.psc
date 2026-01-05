ScriptName TDL_MCM_Stream extends Quest

TDL_StreamController Property StreamController Auto

; ================= OIDs =================
Int OID_ComedyArena
Int OID_ComedyHorror
Int OID_ComedyFakeHero

Int OID_ChaosLowG
Int OID_ChaosBackfire

Int OID_SummonSkeleton
Int OID_SummonDragon

Int OID_GigantBig
Int OID_GigantSpeed

Int OID_WeatherStorm

; ================= BUILD PAGE =================
Function BuildPage(SKI_ConfigBase mcm)

	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	; ===== LEFT COLUMN =====
	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$TDL_Stream_Comedy")
	OID_ComedyArena     = mcm.AddTextOption("$TDL_Stream_ComedyArena", "$ActionActivate")
	OID_ComedyHorror    = mcm.AddTextOption("$TDL_Stream_ComedyHorror", "$ActionActivate")
	OID_ComedyFakeHero  = mcm.AddTextOption("$TDL_Stream_ComedyFakeHero", "$ActionActivate")

	mcm.AddHeaderOption("$TDL_Stream_Chaos")
	OID_ChaosLowG       = mcm.AddTextOption("$TDL_Stream_ChaosLowG", "$ActionActivate")
	OID_ChaosBackfire   = mcm.AddTextOption("$TDL_Stream_ChaosBackfire", "$ActionActivate")

	; ===== RIGHT COLUMN =====
	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$TDL_Stream_Summon")
	OID_SummonSkeleton  = mcm.AddTextOption("$TDL_Stream_SummonSkeleton", "$ActionActivate")
	OID_SummonDragon    = mcm.AddTextOption("$TDL_Stream_SummonDragon", "$ActionActivate")

	mcm.AddHeaderOption("$TDL_Stream_Gigant")
	OID_GigantBig       = mcm.AddTextOption("$TDL_Stream_GigantBig", "$ActionActivate")
	OID_GigantSpeed     = mcm.AddTextOption("$TDL_Stream_GigantSpeed", "$ActionActivate")

	mcm.AddHeaderOption("$TDL_Stream_Weather")
	OID_WeatherStorm   = mcm.AddTextOption("$TDL_Stream_WeatherStorm", "$ActionActivate")

EndFunction

; ================= OPTION SELECT =================
Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)

	If StreamController == None
		Return False
	EndIf

	; ===== COMEDY =====
	If option == OID_ComedyArena
		StreamController.SubmitAction("COMEDY_ARENA", 2)
		Return True
	EndIf

	If option == OID_ComedyHorror
		StreamController.SubmitAction("COMEDY_HORROR", 2)
		Return True
	EndIf

	If option == OID_ComedyFakeHero
		StreamController.SubmitAction("COMEDY_FAKE_HERO", 2)
		Return True
	EndIf

	; ===== CHAOS =====
	If option == OID_ChaosLowG
		StreamController.SubmitAction("CHAOS_LOW_G", 2)
		Return True
	EndIf

	If option == OID_ChaosBackfire
		StreamController.SubmitAction("CHAOS_BACKFIRE", 2)
		Return True
	EndIf

	; ===== SUMMON =====
	If option == OID_SummonSkeleton
		StreamController.SubmitAction("SUMMON_SKELETON", 2)
		Return True
	EndIf

	If option == OID_SummonDragon
		StreamController.SubmitAction("SUMMON_DRAGON", 2)
		Return True
	EndIf

	; ===== GIGANT =====
	If option == OID_GigantBig
		StreamController.SubmitAction("GIGANT_BIG", 2)
		Return True
	EndIf

	If option == OID_GigantSpeed
		StreamController.SubmitAction("GIGANT_SPEED", 2)
		Return True
	EndIf

	; ===== WEATHER =====
	If option == OID_WeatherStorm
		StreamController.SubmitAction("WEATHER_STORM", 2)
		Return True
	EndIf

	Return False
EndFunction