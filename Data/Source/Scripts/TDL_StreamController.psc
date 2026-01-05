ScriptName TDL_StreamController extends Quest

Quest Property MainControllerQuest Auto
GlobalVariable Property TDL_DebugEnabled Auto

Bool _ExternalScheduler = True

; ================= SOURCE PRIORITY =================
Int SOURCE_BEATS  = 1
Int SOURCE_POINTS = 2
Int SOURCE_VOTE   = 3

; ================= CONFLICT GROUPS =================
Int GROUP_NONE      = 0
Int GROUP_SUMMON    = 1
Int GROUP_HUNTER    = 2
Int GROUP_COMEDY    = 3
Int GROUP_CHAOS     = 4
Int GROUP_INVENTORY = 5
Int GROUP_TELEPORT  = 6
Int GROUP_VIRUS     = 7
Int GROUP_WEATHER   = 8
Int GROUP_GIGANT    = 9
Int GROUP_WRATH     = 10

; ================= ACTION TABLE =================
String[] ActionIDs
Int[]    ActionStages
Int[]    ActionGroups
Float[]  ActionCooldowns
Bool[]   ActionEnabled

; ================= STATE =================
Int   _currentIdx = -1
Int   _currentSrc = 0
Float _cooldownEnd = 0.0

Int   _pendingIdx = -1
Int   _pendingSrc = 0

Bool  _busy = false

; ================= INIT =================
Event OnInit()
	_BuildActionTable()
	RegisterForModEvent("TDL_SubmitAction", "OnTDLSubmitAction")
EndEvent

Event OnTDLSubmitAction(String eventName, String strArg, Float numArg, Form sender)
	SubmitAction(strArg, numArg as Int)
EndEvent

; ================= PUBLIC API =================
Bool Function SubmitAction(String actionID, Int sourceType)
	sourceType = _ClampSource(sourceType)

	If _ExternalScheduler
		Int idx = _FindActionIndex(actionID)
		If idx < 0
			Return False
		EndIf
		If !ActionEnabled[idx]
			Return False
		EndIf
		If MainControllerQuest == None
			Return False
		EndIf

		MainControllerQuest.SetStage(ActionStages[idx])
		Return True
	EndIf

	sourceType = _ClampSource(sourceType)

	Int idx = _FindActionIndex(actionID)
	If idx < 0
		_Notify("REJECT unknown action=" + actionID)
		Return False
	EndIf

	If !ActionEnabled[idx]
		_Notify("REJECT disabled action=" + actionID)
		Return False
	EndIf

	If _currentIdx < 0
		_Notify("ACCEPT start action=" + actionID + " src=" + sourceType)
		_StartAction(idx, sourceType)
		Return True
	EndIf

	If sourceType < _currentSrc
		_Notify("ACCEPT pending action=" + actionID + " src=" + sourceType)
		_pendingIdx = idx
		_pendingSrc = sourceType
		Return True
	EndIf

	_Notify("REJECT priority action=" + actionID + " src=" + sourceType + " currentSrc=" + _currentSrc)
	Return False
EndFunction

; ================= UPDATE LOOP =================
Event OnUpdate()
	If _busy
		Return
	EndIf
	_busy = true

	If _currentIdx >= 0
		If Utility.GetCurrentRealTime() < _cooldownEnd
			_busy = false
			RegisterForSingleUpdate(0.5)
			Return
		EndIf
		_ClearCurrent()
	EndIf

	If _pendingIdx >= 0
		Int idx = _pendingIdx
		Int src = _pendingSrc
		_pendingIdx = -1
		_pendingSrc = 0
		_StartAction(idx, src)
	EndIf

	_busy = false
EndEvent

; ================= EXECUTION =================
Function _StartAction(Int idx, Int sourceType)
	If MainControllerQuest == None
		_Notify("ERROR MainControllerQuest None")
		Return
	EndIf

	_currentIdx = idx
	_currentSrc = sourceType
	_cooldownEnd = Utility.GetCurrentRealTime() + ActionCooldowns[idx]

	MainControllerQuest.SetStage(ActionStages[idx])
	RegisterForSingleUpdate(0.5)
EndFunction

Function _ClearCurrent()
	_currentIdx = -1
	_currentSrc = 0
	_cooldownEnd = 0.0
EndFunction

Int Function _ClampSource(Int s)
	If s < SOURCE_BEATS
		Return SOURCE_BEATS
	EndIf
	If s > SOURCE_VOTE
		Return SOURCE_VOTE
	EndIf
	Return s
EndFunction

Function _Notify(String asText)
	If !TDL_DebugEnabled || (TDL_DebugEnabled.GetValueInt() == 1)
		Debug.Trace("TDL StreamController: " + asText)
	EndIf
EndFunction

; ================= ACTION TABLE =================
Function _BuildActionTable()
	; ¬—≈√ќ ACTIONS: 46 (если добавишь/уберЄшь Ч помен€й размер массивов)
	ActionIDs       = new String[46]
	ActionStages    = new Int[46]
	ActionGroups    = new Int[46]
	ActionCooldowns = new Float[46]
	ActionEnabled   = new Bool[46]

	Int i = 0

	; ===== SYSTEM =====
	ActionIDs[i] = "SYSTEM_PING"
	ActionStages[i] = 10
	ActionGroups[i] = GROUP_NONE
	ActionCooldowns[i] = 1.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SYSTEM_HEALING"
	ActionStages[i] = 20
	ActionGroups[i] = GROUP_NONE
	ActionCooldowns[i] = 15.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SYSTEM_BLESSING"
	ActionStages[i] = 30
	ActionGroups[i] = GROUP_NONE
	ActionCooldowns[i] = 45.0
	ActionEnabled[i] = true
	i += 1

	; ===== WRATH (11Ц13) =====
	ActionIDs[i] = "WRATH_11"
	ActionStages[i] = 11
	ActionGroups[i] = GROUP_WRATH
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "WRATH_12"
	ActionStages[i] = 12
	ActionGroups[i] = GROUP_WRATH
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "WRATH_13"
	ActionStages[i] = 13
	ActionGroups[i] = GROUP_WRATH
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	; ===== SUMMON (40Ц46) =====
	ActionIDs[i] = "SUMMON_ANY"
	ActionStages[i] = 40
	ActionGroups[i] = GROUP_SUMMON
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SUMMON_SKELETON"
	ActionStages[i] = 41
	ActionGroups[i] = GROUP_SUMMON
	ActionCooldowns[i] = 10.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SUMMON_ANIMAL"
	ActionStages[i] = 42
	ActionGroups[i] = GROUP_SUMMON
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SUMMON_HUMANOID"
	ActionStages[i] = 43
	ActionGroups[i] = GROUP_SUMMON
	ActionCooldowns[i] = 25.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SUMMON_UNDEAD"
	ActionStages[i] = 44
	ActionGroups[i] = GROUP_SUMMON
	ActionCooldowns[i] = 25.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SUMMON_STRONG"
	ActionStages[i] = 45
	ActionGroups[i] = GROUP_SUMMON
	ActionCooldowns[i] = 40.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "SUMMON_DRAGON"
	ActionStages[i] = 46
	ActionGroups[i] = GROUP_SUMMON
	ActionCooldowns[i] = 90.0
	ActionEnabled[i] = true
	i += 1

	; ===== HUNTER (47) =====
	ActionIDs[i] = "HUNTER_START"
	ActionStages[i] = 47
	ActionGroups[i] = GROUP_HUNTER
	ActionCooldowns[i] = 120.0
	ActionEnabled[i] = true
	i += 1

	; ===== COMEDY (50Ц53) =====
	ActionIDs[i] = "COMEDY_FAKE_HERO"
	ActionStages[i] = 50
	ActionGroups[i] = GROUP_COMEDY
	ActionCooldowns[i] = 120.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "COMEDY_HORROR"
	ActionStages[i] = 51
	ActionGroups[i] = GROUP_COMEDY
	ActionCooldowns[i] = 180.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "COMEDY_ARENA"
	ActionStages[i] = 52
	ActionGroups[i] = GROUP_COMEDY
	ActionCooldowns[i] = 300.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "COMEDY_ESCORT"
	ActionStages[i] = 53
	ActionGroups[i] = GROUP_COMEDY
	ActionCooldowns[i] = 180.0
	ActionEnabled[i] = true
	i += 1

	; ===== CHAOS (70Ц71) =====
	ActionIDs[i] = "CHAOS_LOW_G"
	ActionStages[i] = 70
	ActionGroups[i] = GROUP_CHAOS
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "CHAOS_BACKFIRE"
	ActionStages[i] = 71
	ActionGroups[i] = GROUP_CHAOS
	ActionCooldowns[i] = 90.0
	ActionEnabled[i] = true
	i += 1

	; ===== INVENTORY (80Ц81) =====
	ActionIDs[i] = "INVENTORY_SCATTER"
	ActionStages[i] = 80
	ActionGroups[i] = GROUP_INVENTORY
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "INVENTORY_DROP_ALL"
	ActionStages[i] = 81
	ActionGroups[i] = GROUP_INVENTORY
	ActionCooldowns[i] = 180.0
	ActionEnabled[i] = true
	i += 1

	; ===== TELEPORT (90Ц99) =====
	ActionIDs[i] = "TELEPORT_RANDOM_CITY"
	ActionStages[i] = 90
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 30.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_RANDOM_DANGER"
	ActionStages[i] = 91
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_HIGH_HROTHGAR"
	ActionStages[i] = 92
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 30.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_WHITERUN"
	ActionStages[i] = 93
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_SOLITUDE"
	ActionStages[i] = 94
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_WINDHELM"
	ActionStages[i] = 95
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_RIFTEN"
	ActionStages[i] = 96
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_MARKARTH"
	ActionStages[i] = 97
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_FALKREATH"
	ActionStages[i] = 98
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "TELEPORT_DAWNSTAR"
	ActionStages[i] = 99
	ActionGroups[i] = GROUP_TELEPORT
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	; ===== VIRUS (100Ц102) =====
	ActionIDs[i] = "VIRUS_DISEASE"
	ActionStages[i] = 100
	ActionGroups[i] = GROUP_VIRUS
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "VIRUS_WEREWOLF"
	ActionStages[i] = 101
	ActionGroups[i] = GROUP_VIRUS
	ActionCooldowns[i] = 240.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "VIRUS_VAMPIRE"
	ActionStages[i] = 102
	ActionGroups[i] = GROUP_VIRUS
	ActionCooldowns[i] = 240.0
	ActionEnabled[i] = true
	i += 1

	; ===== WEATHER (110Ц114, 119) =====
	ActionIDs[i] = "WEATHER_CLEAR"
	ActionStages[i] = 110
	ActionGroups[i] = GROUP_WEATHER
	ActionCooldowns[i] = 20.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "WEATHER_RAIN"
	ActionStages[i] = 111
	ActionGroups[i] = GROUP_WEATHER
	ActionCooldowns[i] = 30.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "WEATHER_SNOW"
	ActionStages[i] = 112
	ActionGroups[i] = GROUP_WEATHER
	ActionCooldowns[i] = 30.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "WEATHER_STORM"
	ActionStages[i] = 113
	ActionGroups[i] = GROUP_WEATHER
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "WEATHER_FOG"
	ActionStages[i] = 114
	ActionGroups[i] = GROUP_WEATHER
	ActionCooldowns[i] = 30.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "WEATHER_RESET"
	ActionStages[i] = 119
	ActionGroups[i] = GROUP_WEATHER
	ActionCooldowns[i] = 15.0
	ActionEnabled[i] = true
	i += 1

	; ===== GIGANT (120Ц124) =====
	ActionIDs[i] = "GIGANT_BIG"
	ActionStages[i] = 120
	ActionGroups[i] = GROUP_GIGANT
	ActionCooldowns[i] = 90.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "GIGANT_SMALL"
	ActionStages[i] = 121
	ActionGroups[i] = GROUP_GIGANT
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "GIGANT_SPEED"
	ActionStages[i] = 122
	ActionGroups[i] = GROUP_GIGANT
	ActionCooldowns[i] = 90.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "GIGANT_SLOW"
	ActionStages[i] = 123
	ActionGroups[i] = GROUP_GIGANT
	ActionCooldowns[i] = 60.0
	ActionEnabled[i] = true
	i += 1

	ActionIDs[i] = "GIGANT_RESET"
	ActionStages[i] = 124
	ActionGroups[i] = GROUP_GIGANT
	ActionCooldowns[i] = 30.0
	ActionEnabled[i] = true
	i += 1
EndFunction

; ================= UTILS =================
Int Function _FindActionIndex(String id)
	Int i = 0
	While i < ActionIDs.Length
		If ActionIDs[i] == id
			Return i
		EndIf
		i += 1
	EndWhile
	Return -1
EndFunction