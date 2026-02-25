Scriptname TDL_UIStatMenu Hidden

Function Open(TDL_StatsQuest stats) Global
	If stats == None
		Debug.Notification("TDL: StatsQuest not set")
		Return
	EndIf
	_ShowGroups(stats)
EndFunction

Function _ShowGroups(TDL_StatsQuest stats) Global
	UIListMenu m = UIExtensions.GetMenu("UIListMenu") as UIListMenu
	If m == None
		Debug.Trace("TDL_UIStatMenu: UIListMenu not available")
		Return
	EndIf

	m.ResetMenu()
	m.AddEntryItem("Reset statistics")
	m.AddEntryItem("Exit")

	m.AddEntryItem("Other")
	m.AddEntryItem("Chaos")
	m.AddEntryItem("Show")
	m.AddEntryItem("Wrath")
	m.AddEntryItem("Teleport")
	m.AddEntryItem("Summon")
	m.AddEntryItem("Weather")
	m.AddEntryItem("Inventory")
	m.AddEntryItem("Characteristic")
	m.AddEntryItem("Virus")
	m.AddEntryItem("Force")

	m.OpenMenu()
	Int r = m.GetResultInt()

	If r == 0
		stats.ResetSession()
		_ShowGroups(stats)
		Return
	ElseIf r == 1
		Return
	ElseIf r == 2
		_ShowGroup_Other(stats)
	ElseIf r == 3
		_ShowGroup_Chaos(stats)
	ElseIf r == 4
		_ShowGroup_Show(stats)
	ElseIf r == 5
		_ShowGroup_Wrath(stats)
	ElseIf r == 6
		_ShowGroup_Teleport(stats)
	ElseIf r == 7
		_ShowGroup_Summon(stats)
	ElseIf r == 8
		_ShowGroup_Weather(stats)
	ElseIf r == 9
		_ShowGroup_Inventory(stats)
	ElseIf r == 10
		_ShowGroup_Characteristic(stats)
	ElseIf r == 11
		_ShowGroup_Virus(stats)
	ElseIf r == 12
		_ShowGroup_Force(stats)
	EndIf
EndFunction

Function _ShowStages(TDL_StatsQuest stats, String title, Int[] stages, String[] names) Global
	UIListMenu m = UIExtensions.GetMenu("UIListMenu") as UIListMenu
	If m == None
		Return
	EndIf

	m.ResetMenu()
	m.AddEntryItem("<<< Back")
	m.AddEntryItem("Exit")

	Int i = 0
	While i < stages.Length
		Int st = stages[i]
		Int cnt = stats.GetStageCount(st)
		m.AddEntryItem(names[i] + " [" + st + "]: " + cnt)
		i = i + 1
	EndWhile

	m.OpenMenu()
	Int r = m.GetResultInt()

	If r == 0
		_ShowGroups(stats)
		Return
	ElseIf r == 1
		Return
	EndIf

	_ShowStages(stats, title, stages, names)
EndFunction

; ===== GROUPS =====

Function _ShowGroup_Other(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Other", _Stages_Other(), _Names_Other())
EndFunction

Function _ShowGroup_Chaos(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Chaos", _Stages_Chaos(), _Names_Chaos())
EndFunction

Function _ShowGroup_Show(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Show", _Stages_Show(), _Names_Show())
EndFunction

Function _ShowGroup_Wrath(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Wrath", _Stages_Wrath(), _Names_Wrath())
EndFunction

Function _ShowGroup_Teleport(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Teleport", _Stages_Teleport(), _Names_Teleport())
EndFunction

Function _ShowGroup_Summon(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Summon", _Stages_Summon(), _Names_Summon())
EndFunction

Function _ShowGroup_Weather(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Weather", _Stages_Weather(), _Names_Weather())
EndFunction

Function _ShowGroup_Inventory(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Inventory", _Stages_Inventory(), _Names_Inventory())
EndFunction

Function _ShowGroup_Characteristic(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Characteristic", _Stages_Characteristic(), _Names_Characteristic())
EndFunction

Function _ShowGroup_Virus(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Virus", _Stages_Virus(), _Names_Virus())
EndFunction

Function _ShowGroup_Force(TDL_StatsQuest stats) Global
	_ShowStages(stats, "Force", _Stages_Force(), _Names_Force())
EndFunction

; ===== DATA =====

Int[] Function _Stages_Other() Global
	Int[] a = new Int[2]
	a[0] = 20
	a[1] = 30
	Return a
EndFunction

String[] Function _Names_Other() Global
	String[] a = new String[2]
	a[0] = "Healing"
	a[1] = "Bleassing"
	Return a
EndFunction

Int[] Function _Stages_Chaos() Global
	Int[] a = new Int[2]
	a[0] = 70
	a[1] = 71
	Return a
EndFunction

String[] Function _Names_Chaos() Global
	String[] a = new String[2]
	a[0] = "Low gravity"
	a[1] = "Backfire"
	Return a
EndFunction

Int[] Function _Stages_Show() Global
	Int[] a = new Int[5]
	a[0] = 50
	a[1] = 51
	a[2] = 52
	a[3] = 53
	a[4] = 47
	Return a
EndFunction

String[] Function _Names_Show() Global
	String[] a = new String[5]
	a[0] = "\"Hero\""
	a[1] = "Horror-mod"
	a[2] = "Wave of enemies"
	a[3] = "Escort"
	a[4] = "Hunter"
	Return a
EndFunction

Int[] Function _Stages_Wrath() Global
	Int[] a = new Int[3]
	a[0] = 11
	a[1] = 12
	a[2] = 13
	Return a
EndFunction

String[] Function _Names_Wrath() Global
	String[] a = new String[3]
	a[0] = "Storm"
	a[1] = "Fire"
	a[2] = "Frost"
	Return a
EndFunction

Int[] Function _Stages_Teleport() Global
	Int[] a = new Int[10]
	a[0] = 90
	a[1] = 91
	a[2] = 92
	a[3] = 93
	a[4] = 94
	a[5] = 95
	a[6] = 96
	a[7] = 97
	a[8] = 98
	a[9] = 99
	Return a
EndFunction

String[] Function _Names_Teleport() Global
	String[] a = new String[10]
	a[0] = "Random city"
	a[1] = "Random location"
	a[2] = "Hight Hrothar"
	a[3] = "Whiterun"
	a[4] = "Solitude"
	a[5] = "Windhelm"
	a[6] = "Riften"
	a[7] = "Markarth"
	a[8] = "Falkreath"
	a[9] = "Dawnstar"
	Return a
EndFunction

Int[] Function _Stages_Summon() Global
	Int[] a = new Int[7]
	a[0] = 40
	a[1] = 41
	a[2] = 42
	a[3] = 43
	a[4] = 44
	a[5] = 45
	a[6] = 46
	Return a
EndFunction

String[] Function _Names_Summon() Global
	String[] a = new String[7]
	a[0] = "Any"
	a[1] = "Skeleton"
	a[2] = "Animal"
	a[3] = "Humanoid"
	a[4] = "Undead"
	a[5] = "Strong"
	a[6] = "Dragon"
	Return a
EndFunction

Int[] Function _Stages_Weather() Global
	Int[] a = new Int[6]
	a[0] = 110
	a[1] = 111
	a[2] = 112
	a[3] = 113
	a[4] = 114
	a[5] = 119
	Return a
EndFunction

String[] Function _Names_Weather() Global
	String[] a = new String[6]
	a[0] = "Clear"
	a[1] = "Rain"
	a[2] = "Snow"
	a[3] = "Storm"
	a[4] = "Fog"
	a[5] = "Reset"
	Return a
EndFunction

Int[] Function _Stages_Inventory() Global
	Int[] a = new Int[2]
	a[0] = 80
	a[1] = 81
	Return a
EndFunction

String[] Function _Names_Inventory() Global
	String[] a = new String[2]
	a[0] = "Scatter"
	a[1] = "Drop All"
	Return a
EndFunction

Int[] Function _Stages_Characteristic() Global
	Int[] a = new Int[5]
	a[0] = 120
	a[1] = 121
	a[2] = 122
	a[3] = 123
	a[4] = 124
	Return a
EndFunction

String[] Function _Names_Characteristic() Global
	String[] a = new String[5]
	a[0] = "Big"
	a[1] = "Small"
	a[2] = "Speed"
	a[3] = "Slow"
	a[4] = "Reset"
	Return a
EndFunction

Int[] Function _Stages_Virus() Global
	Int[] a = new Int[3]
	a[0] = 100
	a[1] = 101
	a[2] = 102
	Return a
EndFunction

String[] Function _Names_Virus() Global
	String[] a = new String[3]
	a[0] = "Disease"
	a[1] = "Werewolf"
	a[2] = "Vampire"
	Return a
EndFunction

Int[] Function _Stages_Force() Global
	Int[] a = new Int[12]
	a[0] = 20
	a[1] = 90
	a[2] = 91
	a[3] = 40
	a[4] = 41
	a[5] = 42
	a[6] = 43
	a[7] = 44
	a[8] = 45
	a[9] = 46
	a[10] = 100
	a[11] = 80
	Return a
EndFunction

String[] Function _Names_Force() Global
	String[] a = new String[12]
	a[0] = "Healing"
	a[1] = "Random city"
	a[2] = "Random location"
	a[3] = "Any"
	a[4] = "Skeleton"
	a[5] = "Animal"
	a[6] = "Humanoid"
	a[7] = "Undead"
	a[8] = "Strong"
	a[9] = "Dragon"
	a[10] = "Disease"
	a[11] = "Scatter"
	Return a
EndFunction