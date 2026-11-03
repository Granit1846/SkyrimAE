ScriptName TDL_MCM_Comedy extends Quest

Quest Property MainControllerQuest Auto

GlobalVariable Property FakeHeroDuration Auto
GlobalVariable Property FakeHeroActionInterval Auto
GlobalVariable Property FakeHeroDamageMult Auto
GlobalVariable Property FakeHeroPushForce Auto
GlobalVariable Property FakeHeroShoutChance Auto
GlobalVariable Property FakeHeroSpellChance Auto
GlobalVariable Property HorrorDuration Auto
GlobalVariable Property HorrorSpawnDistance Auto
GlobalVariable Property HorrorTeleportDistance Auto
GlobalVariable Property HorrorMaxDistance Auto
GlobalVariable Property HorrorHealth Auto
GlobalVariable Property ArenaWaves Auto
GlobalVariable Property ArenaPerWave Auto
GlobalVariable Property ArenaWaveInterval Auto
GlobalVariable Property ArenaSpawnRadius Auto
GlobalVariable Property ArenaTimeoutMinutes Auto ; NEW
GlobalVariable Property TDL_ArenaPrepSeconds Auto
GlobalVariable Property TDL_ArenaReturnDelay Auto
GlobalVariable Property EscortDuration Auto

Int FLAG_HAS_DEFAULT = 16

Int OID_Start50 = -1
Int OID_Start51 = -1
Int OID_Start52 = -1
Int OID_Start53 = -1

Int OID_FakeHeroDuration = -1
Int OID_FakeHeroActionInterval = -1
Int OID_FakeHeroDamageMult = -1
Int OID_FakeHeroPushForce = -1
Int OID_FakeHeroShoutChance = -1
Int OID_FakeHeroSpellChance = -1
Int OID_HorrorDuration = -1
Int OID_HorrorSpawnDist = -1
Int OID_HorrorTeleportDist = -1
Int OID_HorrorMaxDist = -1
Int OID_HorrorHealth = -1
Int OID_ArenaWaves = -1
Int OID_ArenaPerWave = -1
Int OID_ArenaWaveInterval = -1
Int OID_ArenaSpawnRadius = -1
Int OID_ArenaTimeoutMinutes = -1 ; NEW
Int OID_ArenaPrepSeconds = -1
Int OID_ArenaReturnDelay = -1
Int OID_EscortDuration = -1

Function BuildPage(SKI_ConfigBase mcm)
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$ComedyHeaderFakeHero")
	OID_Start50 = mcm.AddTextOption("$ComedyEventFakeHero", "$ActionActivate")
	OID_FakeHeroDuration = mcm.AddSliderOption("$ComedyFakeHeroDuration", FakeHeroDuration.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_FakeHeroActionInterval = mcm.AddSliderOption("$ComedyFakeHeroActionInterval", FakeHeroActionInterval.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_FakeHeroDamageMult = mcm.AddSliderOption("$ComedyFakeHeroDamageMult", FakeHeroDamageMult.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_FakeHeroPushForce = mcm.AddSliderOption("$ComedyFakeHeroPushForce", FakeHeroPushForce.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_FakeHeroShoutChance = mcm.AddSliderOption("$ComedyFakeHeroShoutChance", FakeHeroShoutChance.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_FakeHeroSpellChance = mcm.AddSliderOption("$ComedyFakeHeroSpellChance", FakeHeroSpellChance.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	mcm.AddHeaderOption("$ComedyHeaderEscort")
	OID_Start53 = mcm.AddTextOption("$ComedyEventEscort", "$ActionStart")
	OID_EscortDuration = mcm.AddSliderOption("$ComedyEscortDuration", EscortDuration.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$ComedyHeaderHorror")
	OID_Start51 = mcm.AddTextOption("$ComedyEventHorror", "$ActionStart")
	OID_HorrorDuration = mcm.AddSliderOption("$ComedyHorrorDuration", HorrorDuration.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_HorrorSpawnDist = mcm.AddSliderOption("$ComedyHorrorSpawn", HorrorSpawnDistance.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_HorrorTeleportDist = mcm.AddSliderOption("$ComedyHorrorTeleport", HorrorTeleportDistance.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_HorrorMaxDist = mcm.AddSliderOption("$ComedyHorrorMaxDist", HorrorMaxDistance.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_HorrorHealth = mcm.AddSliderOption("$ComedyHorrorHealth", HorrorHealth.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	mcm.AddHeaderOption("$ComedyHeaderArena")
	OID_Start52 = mcm.AddTextOption("$ComedyEventArena", "$ActionStart")
	OID_ArenaWaves = mcm.AddSliderOption("$ComedyArenaWaves", ArenaWaves.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_ArenaPerWave = mcm.AddSliderOption("$ComedyArenaPerWave", ArenaPerWave.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_ArenaWaveInterval = mcm.AddSliderOption("$ComedyArenaInterval", ArenaWaveInterval.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_ArenaSpawnRadius = mcm.AddSliderOption("$ComedyArenaRadius", ArenaSpawnRadius.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_ArenaTimeoutMinutes = mcm.AddSliderOption("$ComedyArenaTimeoutMinutes", ArenaTimeoutMinutes.GetValue(), "{1}", FLAG_HAS_DEFAULT) ; NEW
	If TDL_ArenaPrepSeconds
		OID_ArenaPrepSeconds = mcm.AddSliderOption("$ComedyArenaPrepSeconds", TDL_ArenaPrepSeconds.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	EndIf
	If TDL_ArenaReturnDelay
		OID_ArenaReturnDelay = mcm.AddSliderOption("$ComedyArenaReturnDelay", TDL_ArenaReturnDelay.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	EndIf
EndFunction

Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)
	If MainControllerQuest == None
		Return False
	EndIf
	If option == OID_Start50
		MainControllerQuest.SetStage(50)
		Return True
	EndIf
	If option == OID_Start51
		MainControllerQuest.SetStage(51)
		Return True
	EndIf
	If option == OID_Start52
		MainControllerQuest.SetStage(52)
		Return True
	EndIf
	If option == OID_Start53
		MainControllerQuest.SetStage(53)
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)
	If option == OID_FakeHeroDuration
		FakeHeroDuration.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_FakeHeroActionInterval
		FakeHeroActionInterval.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_FakeHeroDamageMult
		FakeHeroDamageMult.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_FakeHeroPushForce
		FakeHeroPushForce.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_FakeHeroShoutChance
		FakeHeroShoutChance.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_FakeHeroSpellChance
		FakeHeroSpellChance.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_HorrorDuration
		HorrorDuration.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_HorrorSpawnDist
		HorrorSpawnDistance.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_HorrorTeleportDist
		HorrorTeleportDistance.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_HorrorMaxDist
		HorrorMaxDistance.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_HorrorHealth
		HorrorHealth.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ArenaWaves
		ArenaWaves.SetValueInt(value as Int)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ArenaPerWave
		ArenaPerWave.SetValueInt(value as Int)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ArenaWaveInterval
		ArenaWaveInterval.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_ArenaSpawnRadius
		ArenaSpawnRadius.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ArenaTimeoutMinutes
		ArenaTimeoutMinutes.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{1}")
		Return True
	EndIf
	If option == OID_ArenaPrepSeconds && TDL_ArenaPrepSeconds
		TDL_ArenaPrepSeconds.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ArenaReturnDelay && TDL_ArenaReturnDelay
		TDL_ArenaReturnDelay.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_EscortDuration
		EscortDuration.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)
	If option == OID_FakeHeroDuration
		FakeHeroDuration.SetValue(120)
		mcm.SetSliderOptionValue(option, 120, "{0}")
		Return True
	EndIf
	If option == OID_FakeHeroActionInterval
		FakeHeroActionInterval.SetValue(3.0)
		mcm.SetSliderOptionValue(option, 3.0, "{2}")
		Return True
	EndIf
	If option == OID_FakeHeroDamageMult
		FakeHeroDamageMult.SetValue(1.0)
		mcm.SetSliderOptionValue(option, 1.0, "{2}")
		Return True
	EndIf
	If option == OID_FakeHeroPushForce
		FakeHeroPushForce.SetValue(5)
		mcm.SetSliderOptionValue(option, 5, "{0}")
		Return True
	EndIf
	If option == OID_FakeHeroShoutChance
		FakeHeroShoutChance.SetValue(30)
		mcm.SetSliderOptionValue(option, 30, "{0}")
		Return True
	EndIf
	If option == OID_FakeHeroSpellChance
		FakeHeroSpellChance.SetValue(30)
		mcm.SetSliderOptionValue(option, 30, "{0}")
		Return True
	EndIf
	If option == OID_HorrorDuration
		HorrorDuration.SetValue(120)
		mcm.SetSliderOptionValue(option, 120, "{0}")
		Return True
	EndIf
	If option == OID_HorrorSpawnDist
		HorrorSpawnDistance.SetValue(800)
		mcm.SetSliderOptionValue(option, 800, "{0}")
		Return True
	EndIf
	If option == OID_HorrorTeleportDist
		HorrorTeleportDistance.SetValue(600)
		mcm.SetSliderOptionValue(option, 600, "{0}")
		Return True
	EndIf
	If option == OID_HorrorMaxDist
		HorrorMaxDistance.SetValue(3000)
		mcm.SetSliderOptionValue(option, 3000, "{0}")
		Return True
	EndIf
	If option == OID_HorrorHealth
		HorrorHealth.SetValue(300)
		mcm.SetSliderOptionValue(option, 300, "{0}")
		Return True
	EndIf
	If option == OID_ArenaWaves
		ArenaWaves.SetValueInt(3)
		mcm.SetSliderOptionValue(option, 3, "{0}")
		Return True
	EndIf
	If option == OID_ArenaPerWave
		ArenaPerWave.SetValueInt(3)
		mcm.SetSliderOptionValue(option, 3, "{0}")
		Return True
	EndIf
	If option == OID_ArenaWaveInterval
		ArenaWaveInterval.SetValue(3.0)
		mcm.SetSliderOptionValue(option, 3.0, "{2}")
		Return True
	EndIf
	If option == OID_ArenaSpawnRadius
		ArenaSpawnRadius.SetValue(800)
		mcm.SetSliderOptionValue(option, 800, "{0}")
		Return True
	EndIf
	If option == OID_ArenaTimeoutMinutes
		ArenaTimeoutMinutes.SetValue(10.0)
		mcm.SetSliderOptionValue(option, 10.0, "{1}")
		Return True
	EndIf
	If option == OID_ArenaPrepSeconds && TDL_ArenaPrepSeconds
		TDL_ArenaPrepSeconds.SetValue(30.0)
		mcm.SetSliderOptionValue(option, 30.0, "{0}")
		Return True
	EndIf
	If option == OID_ArenaReturnDelay && TDL_ArenaReturnDelay
		TDL_ArenaReturnDelay.SetValue(10.0)
		mcm.SetSliderOptionValue(option, 10.0, "{0}")
		Return True
	EndIf
	If option == OID_EscortDuration
		EscortDuration.SetValue(120)
		mcm.SetSliderOptionValue(option, 120, "{0}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)

	; ===== STAGE 50 — FAKE HERO =====
	If option == OID_FakeHeroDuration
		If FakeHeroDuration != None
			mcm.SetSliderDialogStartValue(FakeHeroDuration.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(120)
		mcm.SetSliderDialogRange(10, 600)
		mcm.SetSliderDialogInterval(10)
		Return True
	EndIf

	If option == OID_FakeHeroActionInterval
		If FakeHeroActionInterval != None
			mcm.SetSliderDialogStartValue(FakeHeroActionInterval.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(3.0)
		mcm.SetSliderDialogRange(0.5, 10.0)
		mcm.SetSliderDialogInterval(0.5)
		Return True
	EndIf

	If option == OID_FakeHeroDamageMult
		If FakeHeroDamageMult != None
			mcm.SetSliderDialogStartValue(FakeHeroDamageMult.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(1.0)
		mcm.SetSliderDialogRange(0.2, 5.0)
		mcm.SetSliderDialogInterval(0.1)
		Return True
	EndIf

	If option == OID_FakeHeroPushForce
		If FakeHeroPushForce != None
			mcm.SetSliderDialogStartValue(FakeHeroPushForce.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(5)
		mcm.SetSliderDialogRange(0, 50)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_FakeHeroShoutChance || option == OID_FakeHeroSpellChance
		If option == OID_FakeHeroShoutChance
			If FakeHeroShoutChance != None
				mcm.SetSliderDialogStartValue(FakeHeroShoutChance.GetValue())
			EndIf
			mcm.SetSliderDialogDefaultValue(30)
		ElseIf option == OID_FakeHeroSpellChance
			If FakeHeroSpellChance != None
				mcm.SetSliderDialogStartValue(FakeHeroSpellChance.GetValue())
			EndIf
			mcm.SetSliderDialogDefaultValue(30)
		EndIf
		mcm.SetSliderDialogRange(0, 100)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	; ===== STAGE 51 — HORROR =====
	If option == OID_HorrorDuration
		If HorrorDuration != None
			mcm.SetSliderDialogStartValue(HorrorDuration.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(120)
		mcm.SetSliderDialogRange(10, 600)
		mcm.SetSliderDialogInterval(10)
		Return True
	EndIf

	If option == OID_HorrorSpawnDist
		If HorrorSpawnDistance != None
			mcm.SetSliderDialogStartValue(HorrorSpawnDistance.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(800)
		mcm.SetSliderDialogRange(200, 3000)
		mcm.SetSliderDialogInterval(100)
		Return True
	EndIf

	If option == OID_HorrorTeleportDist
		If HorrorTeleportDistance != None
			mcm.SetSliderDialogStartValue(HorrorTeleportDistance.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(600)
		mcm.SetSliderDialogRange(200, 2000)
		mcm.SetSliderDialogInterval(100)
		Return True
	EndIf

	If option == OID_HorrorMaxDist
		If HorrorMaxDistance != None
			mcm.SetSliderDialogStartValue(HorrorMaxDistance.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(3000)
		mcm.SetSliderDialogRange(1000, 6000)
		mcm.SetSliderDialogInterval(250)
		Return True
	EndIf

	If option == OID_HorrorHealth
		If HorrorHealth != None
			mcm.SetSliderDialogStartValue(HorrorHealth.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(300)
		mcm.SetSliderDialogRange(50, 5000)
		mcm.SetSliderDialogInterval(50)
		Return True
	EndIf

	; ===== STAGE 52 — ARENA =====
	If option == OID_ArenaWaves
		If ArenaWaves != None
			mcm.SetSliderDialogStartValue(ArenaWaves.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(3)
		mcm.SetSliderDialogRange(1, 10)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_ArenaPerWave
		If ArenaPerWave != None
			mcm.SetSliderDialogStartValue(ArenaPerWave.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(3)
		mcm.SetSliderDialogRange(1, 20)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_ArenaWaveInterval
		If ArenaWaveInterval != None
			mcm.SetSliderDialogStartValue(ArenaWaveInterval.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(3.0)
		mcm.SetSliderDialogRange(0.5, 10.0)
		mcm.SetSliderDialogInterval(0.5)
		Return True
	EndIf

	If option == OID_ArenaSpawnRadius
		If ArenaSpawnRadius != None
			mcm.SetSliderDialogStartValue(ArenaSpawnRadius.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(800)
		mcm.SetSliderDialogRange(200, 3000)
		mcm.SetSliderDialogInterval(100)
		Return True
	EndIf

	If option == OID_ArenaTimeoutMinutes
		If ArenaTimeoutMinutes != None
			mcm.SetSliderDialogStartValue(ArenaTimeoutMinutes.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(10.0)
		mcm.SetSliderDialogRange(5.0, 20.0)
		mcm.SetSliderDialogInterval(0.5)
		Return True
	EndIf

	If option == OID_ArenaPrepSeconds
		If TDL_ArenaPrepSeconds != None
			mcm.SetSliderDialogStartValue(TDL_ArenaPrepSeconds.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(30.0)
		mcm.SetSliderDialogRange(0, 120)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf
	If option == OID_ArenaReturnDelay
		If TDL_ArenaReturnDelay != None
			mcm.SetSliderDialogStartValue(TDL_ArenaReturnDelay.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(10.0)
		mcm.SetSliderDialogRange(0, 60)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	; ===== STAGE 53 — ESCORT =====
	If option == OID_EscortDuration
		If EscortDuration != None
			mcm.SetSliderDialogStartValue(EscortDuration.GetValue())
		EndIf
		mcm.SetSliderDialogDefaultValue(120)
		mcm.SetSliderDialogRange(30, 600)
		mcm.SetSliderDialogInterval(10)
		Return True
	EndIf

	Return False
EndFunction