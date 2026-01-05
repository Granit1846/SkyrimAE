Scriptname TDL_Virus extends Quest

; =====================================================
; TDL_Virus
;
; Stages:
; 100 — random disease
; 101 — timed werewolf (ONLY if not beast)
; 102 — vampire lord (ONLY if not beast)
; =====================================================

GlobalVariable Property TDL_DebugEnabled Auto

; ---------- Stage 100 ----------
FormList Property VirusDiseaseList Auto

; ---------- Stage 101 — Werewolf ----------
Spell Property WerewolfChangeSpell Auto
Race  Property WerewolfRace Auto
GlobalVariable Property Virus_WerewolfDurationGV Auto

; ---------- Stage 102 — Vampire ----------
Spell Property VampireLordChangeSpell Auto
Race  Property VampireLordRace Auto

; ---------- Internal ----------
Bool  _wwActive = false
Float _wwEndRT = 0.0


; =====================================================
; ENTRY POINT
; =====================================================
Bool Function RunStage(Int aiStage, Actor playerRef)
	If !playerRef
		playerRef = Game.GetPlayer()
	EndIf
	If !playerRef
		_LogError("PlayerRef None")
		Return False
	EndIf

	If aiStage == 100
		_RunStage100(playerRef)
		Return True
	ElseIf aiStage == 101
		_RunStage101(playerRef)
		Return True
	ElseIf aiStage == 102
		_RunStage102(playerRef)
		Return True
	EndIf

	Return False
EndFunction


; =====================================================
; SAFETY — forbid beast-on-beast
; =====================================================
Bool Function _IsAllowedForm(Actor p)
	If !p
		Return False
	EndIf

	Race r = p.GetRace()
	If !r
		Return False
	EndIf

	If WerewolfRace && r == WerewolfRace
		Return False
	EndIf
	If VampireLordRace && r == VampireLordRace
		Return False
	EndIf

	Return True
EndFunction


; =====================================================
; STAGE 100 — RANDOM DISEASE
; =====================================================
Function _RunStage100(Actor p)
	If !VirusDiseaseList || VirusDiseaseList.GetSize() <= 0
		_LogError("Disease list empty")
		Return
	EndIf

	Int idx = Utility.RandomInt(0, VirusDiseaseList.GetSize() - 1)
	Spell dis = VirusDiseaseList.GetAt(idx) as Spell
	If !dis
		_LogError("Picked form is not Spell")
		Return
	EndIf

	p.AddSpell(dis, false)
EndFunction


; =====================================================
; STAGE 101 — WEREWOLF
; =====================================================
Function _RunStage101(Actor p)
	If !_IsAllowedForm(p)
		_LogInfo("Werewolf unavailable: beast form")
		Return
	EndIf

	If !WerewolfChangeSpell
		_LogError("WerewolfChangeSpell not set")
		Return
	EndIf

	Float dur = 150.0
	If Virus_WerewolfDurationGV
		dur = Virus_WerewolfDurationGV.GetValue()
	EndIf
	If dur < 5.0
		dur = 5.0
	EndIf

	If p.GetRace() == WerewolfRace
		_wwEndRT = Utility.GetCurrentRealTime() + dur
		RegisterForSingleUpdate(1.0)
		Return
	EndIf

	WerewolfChangeSpell.Cast(p, p)
	_wwActive = true
	_wwEndRT = Utility.GetCurrentRealTime() + dur

	RegisterForSingleUpdate(1.0)
EndFunction


; =====================================================
; STAGE 102 — VAMPIRE LORD
; =====================================================
Function _RunStage102(Actor p)
	If !_IsAllowedForm(p)
		_LogInfo("Vampire unavailable: beast form")
		Return
	EndIf

	If !VampireLordChangeSpell
		_LogError("VampireLordChangeSpell not set")
		Return
	EndIf

	VampireLordChangeSpell.Cast(p, p)
EndFunction


; =====================================================
; UPDATE LOOP (WEREWOLF TIMER ONLY)
; =====================================================
Event OnUpdate()
	Actor p = Game.GetPlayer()
	If !p
		Return
	EndIf

	If _wwActive
		If p.GetRace() != WerewolfRace
			_wwActive = false
			Return
		EndIf

		If Utility.GetCurrentRealTime() >= _wwEndRT
			If WerewolfChangeSpell
				p.DispelSpell(WerewolfChangeSpell)
			EndIf
			_wwActive = false
			Return
		EndIf

		RegisterForSingleUpdate(1.0)
	EndIf
EndEvent


; =====================================================
; RESET
; =====================================================
Event OnReset()
	_wwActive = false
	_wwEndRT = 0.0
EndEvent


; =====================================================
; LOGGING
; =====================================================
Function _LogError(String msg)
	Debug.Trace("[TDL Virus ERROR] " + msg)
	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL Virus] ERROR: " + msg)
	EndIf
EndFunction

Function _LogInfo(String msg)
	Debug.Trace("[TDL Virus] " + msg)
EndFunction