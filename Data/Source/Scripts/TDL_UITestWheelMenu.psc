Scriptname TDL_UITestWheelMenu extends ActiveMagicEffect

; Рабочий вариант: только контроллер
TDL_MainController Property MainController Auto
TDL_StatsQuest Property StatsQuest Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	If akTarget != Game.GetPlayer()
		Return
	EndIf
	_ShowMainPage0()
EndEvent

Bool Function _Run(Int aiStage)
	If MainController == None
		Debug.Notification("TDL: MainController not set")
		Debug.Trace("TDL_UITestWheelMenu: MainController == None")
		Return false
	EndIf
	If StatsQuest != None
		StatsQuest.RecordStage(aiStage)
	EndIf
	MainController.RunStage(aiStage)
	Return true
EndFunction

Int Function _OpenWheel(String title, String[] labels, Bool[] enabled)
	UIExtensions.InitMenu("UIWheelMenu")
	UIExtensions.SetMenuPropertyString("UIWheelMenu", "titleText", title)

	Int i = 0
	While i < 8
		String s = ""
		Bool en = false

		If labels != None && i < labels.Length
			s = labels[i]
		EndIf
		If enabled != None && i < enabled.Length
			en = enabled[i]
		EndIf

		UIExtensions.SetMenuPropertyIndexString("UIWheelMenu", "optionLabelText", i, s)
		UIExtensions.SetMenuPropertyIndexBool("UIWheelMenu", "optionEnabled", i, en)

		i += 1
	EndWhile

	Return UIExtensions.OpenMenu("UIWheelMenu")
EndFunction

; =========================
; MAIN MENU (2 pages)
; =========================
Function _ShowMainPage0()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Other")
	t[1] = TDL_Lang.T("Chaos")
	t[2] = TDL_Lang.T("Show")
	t[3] = TDL_Lang.T("Wrath of Heaven")
	t[4] = TDL_Lang.T("Teleport")
	t[5] = TDL_Lang.T("Summon")
	t[6] = TDL_Lang.T("Weather")
	t[7] = TDL_Lang.T("Next >>>")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true
	e[6] = true
	e[7] = true

	Int r = _OpenWheel("TDL", t, e)
	If r == 0
		_ShowOther()
	ElseIf r == 1
		_ShowChaos()
	ElseIf r == 2
		_ShowShow()
	ElseIf r == 3
		_ShowWrath()
	ElseIf r == 4
		_ShowTeleportPage0()
	ElseIf r == 5
		_ShowSummon()
	ElseIf r == 6
		_ShowWeather()
	ElseIf r == 7
		_ShowMainPage1()
	EndIf
EndFunction

Function _ShowMainPage1()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("<<< Back")
	t[1] = TDL_Lang.T("Inventory")
	t[2] = TDL_Lang.T("Characteristic")
	t[3] = TDL_Lang.T("Virus")
	t[4] = TDL_Lang.T("Force")
	t[5] = TDL_Lang.T("Stat")
	t[6] = TDL_Lang.T("Exit")
	t[7] = ""

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true
	e[6] = true
	e[7] = false

	Int r = _OpenWheel("TDL", t, e)
	If r == 0
		_ShowMainPage0()
	ElseIf r == 1
		_ShowInventory()
	ElseIf r == 2
		_ShowCharacteristic()
	ElseIf r == 3
		_ShowVirus()
	ElseIf r == 4
		_ShowForcePage0()
	ElseIf r == 5
		TDL_UIStatMenu.Open(StatsQuest)
	ElseIf r == 6
		Return
	EndIf
EndFunction

; =========================
; OTHER
; =========================
Function _ShowOther()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Healing")
	t[1] = TDL_Lang.T("Blessing")
	t[2] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true

	Int r = _OpenWheel(TDL_Lang.T("Other"), t, e)
	If r == 0
		_Run(20)
	ElseIf r == 1
		_Run(30)
	EndIf
EndFunction

; =========================
; CHAOS
; =========================
Function _ShowChaos()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Low gravity")
	t[1] = TDL_Lang.T("Backfire")
	t[2] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true

	Int r = _OpenWheel(TDL_Lang.T("Chaos"), t, e)
	If r == 0
		_Run(70)
	ElseIf r == 1
		_Run(71)
	EndIf
EndFunction

; =========================
; SHOW
; =========================
Function _ShowShow()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = "\"Hero\""
	t[1] = TDL_Lang.T("Horror")
	t[2] = TDL_Lang.T("Wave of enemies")
	t[3] = TDL_Lang.T("Escort")
	t[4] = TDL_Lang.T("Hunter")
	t[5] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true

	Int r = _OpenWheel(TDL_Lang.T("Show"), t, e)
	If r == 0
		_Run(50)
	ElseIf r == 1
		_Run(51)
	ElseIf r == 2
		_Run(52)
	ElseIf r == 3
		_Run(53)
	ElseIf r == 4
		_Run(47)
	EndIf
EndFunction

; =========================
; WRATH
; =========================
Function _ShowWrath()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Storm")
	t[1] = TDL_Lang.T("Fire")
	t[2] = TDL_Lang.T("Frost")
	t[3] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true

	Int r = _OpenWheel(TDL_Lang.T("Wrath of Heaven"), t, e)
	If r == 0
		_Run(11)
	ElseIf r == 1
		_Run(12)
	ElseIf r == 2
		_Run(13)
	EndIf
EndFunction

; =========================
; TELEPORT (2 pages)
; =========================
Function _ShowTeleportPage0()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Random city")
	t[1] = TDL_Lang.T("Random location")
	t[2] = TDL_Lang.T("High Hrothgar")
	t[3] = TDL_Lang.T("Whiterun")
	t[4] = TDL_Lang.T("Solitude")
	t[5] = TDL_Lang.T("Windhelm")
	t[6] = TDL_Lang.T("Riften")
	t[7] = TDL_Lang.T("Next >>>")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true
	e[6] = true
	e[7] = true

	Int r = _OpenWheel(TDL_Lang.T("Teleport"), t, e)
	If r == 0
		_Run(90)
	ElseIf r == 1
		_Run(91)
	ElseIf r == 2
		_Run(92)
	ElseIf r == 3
		_Run(93)
	ElseIf r == 4
		_Run(94)
	ElseIf r == 5
		_Run(95)
	ElseIf r == 6
		_Run(96)
	ElseIf r == 7
		_ShowTeleportPage1()
	EndIf
EndFunction

Function _ShowTeleportPage1()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("<<< Back")
	t[1] = TDL_Lang.T("Markarth")
	t[2] = TDL_Lang.T("Falkreath")
	t[3] = TDL_Lang.T("Dawnstar")
	t[4] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true

	Int r = _OpenWheel(TDL_Lang.T("Teleport"), t, e)
	If r == 0
		_ShowTeleportPage0()
	ElseIf r == 1
		_Run(97)
	ElseIf r == 2
		_Run(98)
	ElseIf r == 3
		_Run(99)
	EndIf
EndFunction

; =========================
; SUMMON
; =========================
Function _ShowSummon()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Any")
	t[1] = TDL_Lang.T("Skeleton")
	t[2] = TDL_Lang.T("Animal")
	t[3] = TDL_Lang.T("Humanoid")
	t[4] = TDL_Lang.T("Undead")
	t[5] = TDL_Lang.T("Strong")
	t[6] = TDL_Lang.T("Dragon")
	t[7] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true
	e[6] = true
	e[7] = true

	Int r = _OpenWheel(TDL_Lang.T("Summon"), t, e)
	If r == 0
		_Run(40)
	ElseIf r == 1
		_Run(41)
	ElseIf r == 2
		_Run(42)
	ElseIf r == 3
		_Run(43)
	ElseIf r == 4
		_Run(44)
	ElseIf r == 5
		_Run(45)
	ElseIf r == 6
		_Run(46)
	EndIf
EndFunction

; =========================
; WEATHER
; =========================
Function _ShowWeather()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Clear")
	t[1] = TDL_Lang.T("Rain")
	t[2] = TDL_Lang.T("Snow")
	t[3] = TDL_Lang.T("Storm")
	t[4] = TDL_Lang.T("Fog")
	t[5] = TDL_Lang.T("Reset")
	t[6] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true
	e[6] = true

	Int r = _OpenWheel(TDL_Lang.T("Weather"), t, e)
	If r == 0
		_Run(110)
	ElseIf r == 1
		_Run(111)
	ElseIf r == 2
		_Run(112)
	ElseIf r == 3
		_Run(113)
	ElseIf r == 4
		_Run(114)
	ElseIf r == 5
		_Run(119)
	EndIf
EndFunction

; =========================
; INVENTORY
; =========================
Function _ShowInventory()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Scatter")
	t[1] = TDL_Lang.T("Drop All")
	t[2] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true

	Int r = _OpenWheel(TDL_Lang.T("Inventory"), t, e)
	If r == 0
		_Run(80)
	ElseIf r == 1
		_Run(81)
	EndIf
EndFunction

; =========================
; CHARACTERISTIC
; =========================
Function _ShowCharacteristic()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Big")
	t[1] = TDL_Lang.T("Small")
	t[2] = TDL_Lang.T("Speed")
	t[3] = TDL_Lang.T("Slow")
	t[4] = TDL_Lang.T("Reset")
	t[5] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true

	Int r = _OpenWheel(TDL_Lang.T("Characteristic"), t, e)
	If r == 0
		_Run(120)
	ElseIf r == 1
		_Run(121)
	ElseIf r == 2
		_Run(122)
	ElseIf r == 3
		_Run(123)
	ElseIf r == 4
		_Run(124)
	EndIf
EndFunction

; =========================
; VIRUS
; =========================
Function _ShowVirus()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Disease")
	t[1] = TDL_Lang.T("Werewolf")
	t[2] = TDL_Lang.T("Vampire")
	t[3] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true

	Int r = _OpenWheel(TDL_Lang.T("Virus"), t, e)
	If r == 0
		_Run(100)
	ElseIf r == 1
		_Run(101)
	ElseIf r == 2
		_Run(102)
	EndIf
EndFunction

; =========================================================
; FORCE (как было описано): выбор события -> выбор количества -> выбор интервала -> выполнение
; Реализация: через Papyrus Utility.Wait(interval) и RunStage(stage)
; =========================================================
Function _ShowForcePage0()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("Healing")
	t[1] = TDL_Lang.T("Random city")
	t[2] = TDL_Lang.T("Random location")
	t[3] = TDL_Lang.T("Any")
	t[4] = TDL_Lang.T("Skeleton")
	t[5] = TDL_Lang.T("Animal")
	t[6] = TDL_Lang.T("Humanoid")
	t[7] = TDL_Lang.T("Next >>>")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true
	e[6] = true
	e[7] = true

	Int r = _OpenWheel(TDL_Lang.T("Force"), t, e)
	If r == 0
		_ForceFlow(20)
	ElseIf r == 1
		_ForceFlow(90)
	ElseIf r == 2
		_ForceFlow(91)
	ElseIf r == 3
		_ForceFlow(40)
	ElseIf r == 4
		_ForceFlow(41)
	ElseIf r == 5
		_ForceFlow(42)
	ElseIf r == 6
		_ForceFlow(43)
	ElseIf r == 7
		_ShowForcePage1()
	EndIf
EndFunction

Function _ShowForcePage1()
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	t[0] = TDL_Lang.T("<<< Back")
	t[1] = TDL_Lang.T("Undead")
	t[2] = TDL_Lang.T("Strong")
	t[3] = TDL_Lang.T("Dragon")
	t[4] = TDL_Lang.T("Disease")
	t[5] = TDL_Lang.T("Scatter")
	t[6] = TDL_Lang.T("Exit")

	e[0] = true
	e[1] = true
	e[2] = true
	e[3] = true
	e[4] = true
	e[5] = true
	e[6] = true

	Int r = _OpenWheel(TDL_Lang.T("Force"), t, e)
	If r == 0
		_ShowForcePage0()
	ElseIf r == 1
		_ForceFlow(44)
	ElseIf r == 2
		_ForceFlow(45)
	ElseIf r == 3
		_ForceFlow(46)
	ElseIf r == 4
		_ForceFlow(100)
	ElseIf r == 5
		_ForceFlow(80)
	EndIf
EndFunction

Function _ForceFlow(Int aiStage)
	Int count = _ForcePickCount(aiStage)
	If count <= 0
		Return
	EndIf

	Float interval = _ForcePickInterval()
	If interval <= 0.0
		Return
	EndIf

	; Меню уже закрыто (WheelMenu закрывается при выборе).
	Int i = 0
	While i < count
		_Run(aiStage)
		i += 1
		If i < count
			Utility.Wait(interval)
		EndIf
	EndWhile
EndFunction

Int Function _ForcePickCount(Int aiStage)
	; Списки по твоему описанию
	; Summon: 7/14/21/28/35/42/50
	If aiStage >= 40 && aiStage <= 46
		Return _PickFromIntList(TDL_Lang.T("Count (Summon)"), 7, 14, 21, 28, 35, 42, 50)
	EndIf
	
	If aiStage == 80
		Return _PickFromIntList(TDL_Lang.T("Count (Scatter)"), 4, 5, 6, 7, 8, 9, 10)
	EndIf

	; Teleport random city/location: 1..5
	If aiStage == 90 || aiStage == 91
		Return _PickFromIntList(TDL_Lang.T("Count (Teleport)"), 1, 2, 3, 4, 5, -1, -1)
	EndIf

	; Disease: 2/4/6/8/10/12/14
	If aiStage == 100
		Return _PickFromIntList(TDL_Lang.T("Count (Disease)"), 2, 4, 6, 8, 10, 12, 14)
	EndIf

	; Healing (и прочее, если добавишь): даю разумный дефолт 1..10
	Return _PickFromIntList(TDL_Lang.T("Count"), 1, 2, 3, 5, 7, 9, 10)
EndFunction

Float Function _ForcePickInterval()
	; Интервал: 2/4/6/8/10 секунд (как было описано)
	Int v = _PickFromIntList(TDL_Lang.T("Interval (sec)"), 2, 4, 6, 8, 10, -1, -1)
	If v <= 0
		Return 0.0
	EndIf
	Return v as Float
EndFunction

Int Function _PickFromIntList(String title, Int a, Int b, Int c, Int d, Int ee, Int f, Int g)
	String[] t = new String[8]
	Bool[] e = new Bool[8]

	Int[] vals = new Int[7]
	vals[0] = a
	vals[1] = b
	vals[2] = c
	vals[3] = d
	vals[4] = ee
	vals[5] = f
	vals[6] = g

	Int i = 0
	While i < 7
		If vals[i] > 0
			t[i] = vals[i] as String
			e[i] = true
		Else
			t[i] = ""
			e[i] = false
		EndIf
		i += 1
	EndWhile

	t[7] = TDL_Lang.T("Exit")
	e[7] = true

	Int r = _OpenWheel(title, t, e)
	If r == 7
		Return 0
	EndIf
	If r >= 0 && r < 7
		Return vals[r]
	EndIf
	Return 0
EndFunction