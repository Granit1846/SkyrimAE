Scriptname TDL_SlowFall extends ActiveMagicEffect

GlobalVariable Property TDL_SlowFall_Base Auto
GlobalVariable Property TDL_SlowFall_New Auto
GlobalVariable Property TDL_LowG_Duration Auto

Bool _applied = false
Bool _restored = false

Event OnEffectStart(Actor akTarget, Actor akCaster)
	if akTarget != Game.GetPlayer()
		return
	endif
	_applied = true
	_restored = false
	Utility.SetIniFloat("fInAirFallingCharGravityMult:Havok", TDL_SlowFall_New.GetValue())
	float dur = TDL_LowG_Duration.GetValue()
	if dur <= 0.0
		dur = 0.1
	endif
	RegisterForSingleUpdate(dur)
EndEvent

Event OnUpdate()
	Restore()
	if _applied
		Dispel()
	endif
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	Restore()
EndEvent

Function Restore()
	if _restored
		return
	endif
	_restored = true
	Utility.SetIniFloat("fInAirFallingCharGravityMult:Havok", TDL_SlowFall_Base.GetValue())
EndFunction