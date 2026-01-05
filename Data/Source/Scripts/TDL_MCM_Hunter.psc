ScriptName TDL_MCM_Hunter extends Quest

Quest Property MainControllerQuest Auto
TDL_Hunter Property HunterQuest Auto

GlobalVariable Property HunterDuration Auto
GlobalVariable Property ReAggroInterval Auto
GlobalVariable Property MaxDistance Auto
GlobalVariable Property SpawnOffset Auto
GlobalVariable Property HunterCorpseLifetime Auto

Int FLAG_HAS_DEFAULT = 16

Int OID_Start = -1
Int OID_Stop = -1

Int OID_Duration = -1
Int OID_ReAggro = -1
Int OID_MaxDistance = -1
Int OID_SpawnOffset = -1
Int OID_CorpseTime = -1

Function BuildPage(SKI_ConfigBase mcm)
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$HunterHeaderActions")
	OID_Start = mcm.AddTextOption("$HunterStart", "$ActionStart")
	OID_Stop = mcm.AddTextOption("$HunterStop", "$ActionStop")
	mcm.AddHeaderOption("$HunterHeaderCorpse")
	OID_CorpseTime = mcm.AddSliderOption("$HunterCorpseTime", HunterCorpseLifetime.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$HunterHeaderGeneral")
	OID_Duration = mcm.AddSliderOption("$HunterDuration", HunterDuration.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_ReAggro = mcm.AddSliderOption("$HunterReAggro", ReAggroInterval.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_MaxDistance = mcm.AddSliderOption("$HunterMaxDistance", MaxDistance.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_SpawnOffset = mcm.AddSliderOption("$HunterSpawnOffset", SpawnOffset.GetValue(), "{0}", FLAG_HAS_DEFAULT)
EndFunction

Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)
	If option == OID_Start
		MainControllerQuest.SetStage(47)
		Return True
	EndIf
	If option == OID_Stop
		If HunterQuest
			HunterQuest.StopHunter()
		EndIf
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)
	If option == OID_Duration
		HunterDuration.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_ReAggro
		ReAggroInterval.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_MaxDistance
		MaxDistance.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_SpawnOffset
		SpawnOffset.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_CorpseTime
		HunterCorpseLifetime.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)
	If option == OID_Duration
		HunterDuration.SetValue(90)
		mcm.SetSliderOptionValue(option, 90, "{0}")
		Return True
	EndIf
	If option == OID_ReAggro
		ReAggroInterval.SetValue(4.0)
		mcm.SetSliderOptionValue(option, 4.0, "{2}")
		Return True
	EndIf
	If option == OID_MaxDistance
		MaxDistance.SetValue(5500)
		mcm.SetSliderOptionValue(option, 5500, "{0}")
		Return True
	EndIf
	If option == OID_SpawnOffset
		SpawnOffset.SetValue(1200)
		mcm.SetSliderOptionValue(option, 1200, "{0}")
		Return True
	EndIf
	If option == OID_CorpseTime
		HunterCorpseLifetime.SetValue(20)
		mcm.SetSliderOptionValue(option, 20, "{0}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)

	; ===== DURATION =====
	If option == OID_Duration
		mcm.SetSliderDialogRange(5, 600)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	; ===== RE-AGGRO =====
	If option == OID_ReAggro
		mcm.SetSliderDialogRange(1.0, 10.0)
		mcm.SetSliderDialogInterval(0.5)
		Return True
	EndIf

	; ===== DISTANCE =====
	If option == OID_MaxDistance
		mcm.SetSliderDialogRange(1500, 10000)
		mcm.SetSliderDialogInterval(250)
		Return True
	EndIf

	; ===== SPAWN OFFSET =====
	If option == OID_SpawnOffset
		mcm.SetSliderDialogRange(300, 3000)
		mcm.SetSliderDialogInterval(100)
		Return True
	EndIf

	; ===== CORPSE CLEANUP =====
	If option == OID_CorpseTime
		mcm.SetSliderDialogRange(0, 300)
		mcm.SetSliderDialogInterval(5)
		Return True
	EndIf

	Return False
EndFunction