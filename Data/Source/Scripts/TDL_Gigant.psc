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
Float _originalScale = 1.0
Float _originalDamage = 1.0
Float _originalSpeed = 100.0
Bool _fallAdded = false
Bool _fallBorrowedFromLowG = false


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

	If _sizeStage == 0 && _speedStage == 0
		_originalScale = p.GetScale()
		_originalDamage = p.GetActorValue("WeaponDamageMult")
		_originalSpeed = p.GetActorValue("SpeedMult")
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

	If _sizeStage == 0 && _speedStage == 0
		_originalScale = p.GetScale()
		_originalDamage = p.GetActorValue("WeaponDamageMult")
		_originalSpeed = p.GetActorValue("SpeedMult")
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

	If NoFallingDamageAbility
		If !p.HasSpell(NoFallingDamageAbility)
			p.AddSpell(NoFallingDamageAbility, false)
			_fallAdded = true
		ElseIf _ChaosLowGActive()
			_fallBorrowedFromLowG = true
		EndIf
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

	If NoFallingDamageAbility
		If !p.HasSpell(NoFallingDamageAbility)
			p.AddSpell(NoFallingDamageAbility, false)
			_fallAdded = true
		ElseIf _ChaosLowGActive()
			_fallBorrowedFromLowG = true
		EndIf
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
		p.SetScale(_originalScale)
		p.SetActorValue("WeaponDamageMult", _originalDamage)
		_sizeStage = 0
		_sizeEndTime = 0.0
	EndIf

	If _resetSpeed
		p.SetActorValue("SpeedMult", _originalSpeed)
		_speedStage = 0
		_speedEndTime = 0.0
	EndIf

	If (_fallAdded || _fallBorrowedFromLowG) && _sizeStage != 120 && _speedStage != 122
		If !_ChaosLowGActive()
			If NoFallingDamageAbility && p.HasSpell(NoFallingDamageAbility)
				p.RemoveSpell(NoFallingDamageAbility)
			EndIf
			_fallAdded = false
			_fallBorrowedFromLowG = false
		EndIf
	EndIf
	_resetSize = false
	_resetSpeed = false
EndFunction


; =====================================================
; UPDATE LOOP
; =====================================================
Bool Function _ChaosLowGActive()
	TDL_MainControllerQuest controller = (Self as Quest) as TDL_MainControllerQuest
	If controller
		TDL_ChaosAliasScript chaosAlias = controller.Alias_TDL_ChaosAlias as TDL_ChaosAliasScript
		If chaosAlias
			Return chaosAlias.IsLowGActive()
		EndIf
	EndIf
	Return false
EndFunction

Bool Function NeedsFallProtection()
	Return _sizeStage == 120 || _speedStage == 122
EndFunction

Function EndTransientOnLoad()
	Actor p = Game.GetPlayer()
	If p
		_resetSize = (_sizeStage != 0)
		_resetSpeed = (_speedStage != 0)
		_ApplyReset(p)
	EndIf
EndFunction

Event OnUpdate()
	Actor p = Game.GetPlayer()
	Float now = Utility.GetCurrentRealTime()
	Bool needUpdate = false

	If _sizeStage != 0
		If now >= _sizeEndTime
			_resetSize = true
			_ApplyReset(p)
		Else
			needUpdate = true
		EndIf
	EndIf

	If _speedStage != 0
		If now >= _speedEndTime
			_resetSpeed = true
			_ApplyReset(p)
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