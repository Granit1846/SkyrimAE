Scriptname TDL_SlowFall extends ActiveMagicEffect

GlobalVariable Property TDL_SlowFall_Base Auto
GlobalVariable Property TDL_SlowFall_New Auto
GlobalVariable Property TDL_LowG_Duration Auto

; Low fall gravity can leave the player hanging mid-air until they move (the character
; controller stalls at near-zero vertical speed). While the effect runs we poll the player:
; airborne with no height change for STALL_TICKS polls -> one poll of normal gravity to break it.
Float POLL = 0.25
Int STALL_TICKS = 3
Float STALL_DZ = 1.0

Bool _applied = false
Bool _restored = false
Bool _kicking = false
Float _endRT = 0.0
Float _lastZ = 0.0
Int _stall = 0
Actor _target

Event OnEffectStart(Actor akTarget, Actor akCaster)
	if akTarget != Game.GetPlayer()
		return
	endif
	_target = akTarget
	_applied = true
	_restored = false
	_kicking = false
	_stall = 0
	_lastZ = akTarget.GetPositionZ()
	Utility.SetIniFloat("fInAirFallingCharGravityMult:Havok", TDL_SlowFall_New.GetValue())
	float dur = TDL_LowG_Duration.GetValue()
	if dur <= 0.0
		dur = 0.1
	endif
	_endRT = Utility.GetCurrentRealTime() + dur
	RegisterForSingleUpdate(POLL)
EndEvent

Event OnUpdate()
	if _restored
		return
	endif
	if Utility.GetCurrentRealTime() >= _endRT
		Restore()
		if _applied
			Dispel()
		endif
		return
	endif

	if _kicking
		_kicking = false
		Utility.SetIniFloat("fInAirFallingCharGravityMult:Havok", TDL_SlowFall_New.GetValue())
	endif

	float z = _target.GetPositionZ()
	float dz = z - _lastZ
	if dz < 0.0
		dz = -dz
	endif
	_lastZ = z

	if _target.GetAnimationVariableBool("bInJumpState") && dz < STALL_DZ
		_stall += 1
	else
		_stall = 0
	endif

	if _stall >= STALL_TICKS
		_stall = 0
		_kicking = true
		Utility.SetIniFloat("fInAirFallingCharGravityMult:Havok", TDL_SlowFall_Base.GetValue())
		; The gravity change alone does not wake a resting character controller; a tiny move does
		_target.SetPosition(_target.GetPositionX(), _target.GetPositionY(), z - 1.0)
	endif

	RegisterForSingleUpdate(POLL)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; LowG re-triggered: the ability was removed and added again, and the new instance owns gravity now
	Spell ability = Game.GetFormFromFile(0x039BFF, "TwitchDragonbornLegacy.esp") as Spell  ; TDL_Ability_NoFallingDamage
	if ability && akTarget && akTarget.HasSpell(ability)
		_restored = true
		return
	endif
	Restore()
EndEvent

Function Restore()
	if _restored
		return
	endif
	_restored = true
	Utility.SetIniFloat("fInAirFallingCharGravityMult:Havok", TDL_SlowFall_Base.GetValue())
EndFunction