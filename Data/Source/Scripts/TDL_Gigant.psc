Scriptname TDL_Gigant extends Quest

; =====================================================
; GLOBALS — SCALE
; =====================================================
GlobalVariable Property Gigant_ScaleBigGV Auto
GlobalVariable Property Gigant_ScaleSmallGV Auto

; =====================================================
; GLOBALS — DAMAGE
; =====================================================
GlobalVariable Property Gigant_DamageBigGV Auto
GlobalVariable Property Gigant_DamageSmallGV Auto

; =====================================================
; GLOBALS — SPEED
; =====================================================
GlobalVariable Property Gigant_SpeedMultGV Auto
GlobalVariable Property Gigant_SpeedSlowGV Auto

; =====================================================
; GLOBALS — DURATION
; =====================================================
GlobalVariable Property Gigant_SizeDurationGV Auto
GlobalVariable Property Gigant_SpeedDurationGV Auto

; =====================================================
; SPELLS
; =====================================================
Spell Property NoFallingDamageAbility Auto

; =====================================================
; FORM SAFETY
; =====================================================
Race Property WerewolfRace Auto
Race Property VampireLordRace Auto

; =====================================================
; DEBUG
; =====================================================
GlobalVariable Property TDL_DebugEnabled Auto

; =====================================================
; STATE / TIMERS
; =====================================================
Int _sizeStage = 0          ; 0 / 120 / 121
Float _sizeEndTime = 0.0

Int _speedStage = 0         ; 0 / 122 / 123
Float _speedEndTime = 0.0

Bool _resetSize = false
Bool _resetSpeed = false


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

	; --- SAFETY: forbid beast forms ---
	If !_IsAllowedForm(playerRef)
		Return False
	EndIf

	If aiStage == 120 || aiStage == 121
		_HandleSizeStage(aiStage, playerRef)
		Return True
	ElseIf aiStage == 122 || aiStage == 123
		_HandleSpeedStage(aiStage, playerRef)
		Return True
	ElseIf aiStage == 124
		_resetSize = true
		_resetSpeed = true
		_ApplyReset(playerRef)
		Return True
	EndIf

	Return False
EndFunction


; =====================================================
; SAFETY — forbid beast forms
; =====================================================
Bool Function _IsAllowedForm(Actor p)
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
; SIZE GROUP — 120 / 121
; =====================================================
Function _HandleSizeStage(Int stage, Actor p)
	Float now = Utility.GetCurrentRealTime()

	Float dur = 60.0
	If Gigant_SizeDurationGV
		dur = Gigant_SizeDurationGV.GetValue()
	EndIf

	If _sizeStage == stage
		_sizeEndTime = now + dur
		RegisterForSingleUpdate(0.5)
		Return
	EndIf

	If _sizeStage != 0
		_resetSize = true
		_ApplyReset(p)
	EndIf

	If stage == 120
		_ApplyBig(p)
	Else
		_ApplySmall(p)
	EndIf

	_sizeStage = stage
	_sizeEndTime = now + dur
	RegisterForSingleUpdate(0.5)
EndFunction


; =====================================================
; SPEED GROUP — 122 / 123
; =====================================================
Function _HandleSpeedStage(Int stage, Actor p)
	Float now = Utility.GetCurrentRealTime()

	Float dur = 60.0
	If Gigant_SpeedDurationGV
		dur = Gigant_SpeedDurationGV.GetValue()
	EndIf

	If _speedStage == stage
		_speedEndTime = now + dur
		RegisterForSingleUpdate(0.5)
		Return
	EndIf

	If _speedStage != 0
		_resetSpeed = true
		_ApplyReset(p)
	EndIf

	If stage == 122
		_ApplySpeed(p)
	Else
		_ApplySlow(p)
	EndIf

	_speedStage = stage
	_speedEndTime = now + dur
	RegisterForSingleUpdate(0.5)
EndFunction


; =====================================================
; APPLY — BIG
; =====================================================
Function _ApplyBig(Actor p)
	Float scale = 3.0
	If Gigant_ScaleBigGV
		scale = Gigant_ScaleBigGV.GetValue()
	EndIf
	If scale < 0.1
		scale = 0.1
	EndIf

	Float dmgMult = 6.0
	If Gigant_DamageBigGV
		dmgMult = Gigant_DamageBigGV.GetValue()
	EndIf
	If dmgMult < 0.0
		dmgMult = 0.0
	EndIf

	p.SetScale(scale)
	p.SetActorValue("WeaponDamageMult", dmgMult)

	If NoFallingDamageAbility && !p.HasSpell(NoFallingDamageAbility)
		p.AddSpell(NoFallingDamageAbility, false)
	EndIf
EndFunction


; =====================================================
; APPLY — SMALL
; =====================================================
Function _ApplySmall(Actor p)
	Float scale = 0.33
	If Gigant_ScaleSmallGV
		scale = Gigant_ScaleSmallGV.GetValue()
	EndIf
	If scale < 0.05
		scale = 0.05
	EndIf

	Float dmgMult = 0.5
	If Gigant_DamageSmallGV
		dmgMult = Gigant_DamageSmallGV.GetValue()
	EndIf
	If dmgMult < 0.0
		dmgMult = 0.0
	EndIf

	p.SetScale(scale)
	p.SetActorValue("WeaponDamageMult", dmgMult)
EndFunction


; =====================================================
; APPLY — SPEED
; =====================================================
Function _ApplySpeed(Actor p)
	Float speed = 300.0
	If Gigant_SpeedMultGV
		speed = Gigant_SpeedMultGV.GetValue()
	EndIf
	If speed < 10.0
		speed = 10.0
	EndIf

	p.SetActorValue("SpeedMult", speed)

	If NoFallingDamageAbility && !p.HasSpell(NoFallingDamageAbility)
		p.AddSpell(NoFallingDamageAbility, false)
	EndIf
EndFunction


; =====================================================
; APPLY — SLOW
; =====================================================
Function _ApplySlow(Actor p)
	Float speed = 50.0
	If Gigant_SpeedSlowGV
		speed = Gigant_SpeedSlowGV.GetValue()
	EndIf
	If speed < 1.0
		speed = 1.0
	EndIf

	p.SetActorValue("SpeedMult", speed)
EndFunction


; =====================================================
; RESET
; =====================================================
Function _ApplyReset(Actor p)
	If _resetSize
		p.SetScale(1.0)
		p.SetActorValue("WeaponDamageMult", 1.0)
		_sizeStage = 0
		_sizeEndTime = 0.0
	EndIf

	If _resetSpeed
		p.SetActorValue("SpeedMult", 100.0)
		If NoFallingDamageAbility && p.HasSpell(NoFallingDamageAbility)
			p.RemoveSpell(NoFallingDamageAbility)
		EndIf
		_speedStage = 0
		_speedEndTime = 0.0
	EndIf

	_resetSize = false
	_resetSpeed = false
EndFunction


; =====================================================
; UPDATE LOOP
; =====================================================
Event OnUpdate()
	Actor p = Game.GetPlayer()
	Float now = Utility.GetCurrentRealTime()
	Bool needUpdate = false

	If _sizeStage != 0
		If now >= _sizeEndTime
			_resetSize = true
			_ApplyReset(p)
			Return
		Else
			needUpdate = true
		EndIf
	EndIf

	If _speedStage != 0
		If now >= _speedEndTime
			_resetSpeed = true
			_ApplyReset(p)
			Return
		Else
			needUpdate = true
		EndIf
	EndIf

	If needUpdate
		RegisterForSingleUpdate(0.5)
	EndIf
EndEvent


; =====================================================
; LOGGING
; =====================================================
Function _LogError(String msg)
	Debug.Trace("[TDL Gigant ERROR] " + msg)
	If TDL_DebugEnabled && TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification("[TDL Gigant] ERROR: " + msg)
	EndIf
EndFunction