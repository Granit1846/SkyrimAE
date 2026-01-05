; =========================
; TDL_ChaosAliasScript.psc
; =========================
; “»’»… Alias:
; - Õ≈“ Debug.Notification
; - “ŒÀ‹ Œ Debug.Trace ƒÀﬂ Œÿ»¡Œ 
; - ¡ÂÁ UI-ÒÔ‡Ï‡
; =========================

ScriptName TDL_ChaosAliasScript extends ReferenceAlias

; =========================
; Stage 70 (LowG)
; =========================
Spell        Property NoFallingDamageAbility Auto
VisualEffect Property ChaosVFX Auto

GlobalVariable Property LowG_MultGV Auto
GlobalVariable Property LowG_DurationGV Auto

; =========================
; Stage 71 (Backfire)
; =========================
Spell   Property BackfireSpell Auto
Keyword Property MagicShoutKW Auto

GlobalVariable Property Backfire_DurationGV Auto
GlobalVariable Property Backfire_ChanceGV Auto

; =========================
; Player knockback (shout)
; =========================
Static         Property ShoutPushMarkerBase Auto
GlobalVariable Property ShoutPushDelayGV Auto
GlobalVariable Property ShoutPushOriginDistGV Auto
GlobalVariable Property ShoutPushOriginUpGV Auto
GlobalVariable Property ShoutPushForceGV Auto

; =========================
; Enemy knockback
; =========================
GlobalVariable Property KnockbackRadiusGV Auto
GlobalVariable Property KnockbackForceGV Auto
GlobalVariable Property KnockbackCooldownGV Auto

GlobalVariable Property KnockbackSpellDelayGV Auto
GlobalVariable Property KnockbackBowDelayGV Auto

GlobalVariable Property KnockbackMeleeRadiusGV Auto
GlobalVariable Property KnockbackMeleeConeDegGV Auto
GlobalVariable Property KnockbackMeleeDelayGV Auto

; =========================
; Internal state
; =========================
ObjectReference _pushMarker = None

Float _origJump = 0.0
Bool  _lowGActive = false
Float _lowGEndRT = 0.0
Float _lowGJumpTarget = 0.0

Bool  _backfireActive = false
Float _backfireEndRT = 0.0

Bool  _suppressCast = false
Float _nextKnockbackRT = 0.0
Bool  _animRegistered = false
Bool  _projReg = false

; =========================
; Utils
; =========================
Float Function _GetFloatGV(GlobalVariable gv, Float fallback, Float minVal, Float maxVal)
	Float v = fallback
	If gv != None
		v = gv.GetValue()
	EndIf
	If v < minVal
		v = minVal
	EndIf
	If v > maxVal
		v = maxVal
	EndIf
	Return v
EndFunction

Bool Function _CooldownReady()
	Return (Utility.GetCurrentRealTime() >= _nextKnockbackRT)
EndFunction

Function _CommitCooldown()
	Float cd = _GetFloatGV(KnockbackCooldownGV, 0.35, 0.0, 10.0)
	_nextKnockbackRT = Utility.GetCurrentRealTime() + cd
EndFunction

Function _EnsurePushMarker(Actor p)
	If _pushMarker != None
		Return
	EndIf
	If p == None || ShoutPushMarkerBase == None
		Debug.Trace("[TDL ChaosAlias ERROR] PushMarkerBase or Player is None")
		Return
	EndIf
	_pushMarker = p.PlaceAtMe(ShoutPushMarkerBase, 1, True, True)
EndFunction

Function _DestroyPushMarker()
	If _pushMarker != None
		_pushMarker.DisableNoWait()
		_pushMarker.Delete()
		_pushMarker = None
	EndIf
EndFunction

Function _RegisterProjectileHit()
	If _projReg
		Return
	EndIf
	PO3_Events_Alias.RegisterForProjectileHit(Self)
	_projReg = True
EndFunction

Function _UnregisterProjectileHit()
	If !_projReg
		Return
	EndIf
	PO3_Events_Alias.UnregisterForProjectileHit(Self)
	_projReg = False
EndFunction

; =========================
; Stage 70 ó LowG
; =========================
Function StartLowG(Actor akPlayer)
	If akPlayer == None
		akPlayer = Game.GetPlayer()
	EndIf
	If akPlayer == None
		Debug.Trace("[TDL ChaosAlias ERROR] LowG: player is None")
		Return
	EndIf

	If _origJump <= 0.0
		_origJump = Game.GetGameSettingFloat("fJumpHeightMin")
	EndIf

	Float mult = _GetFloatGV(LowG_MultGV, 3.0, 0.1, 100.0)
	Float dur  = _GetFloatGV(LowG_DurationGV, 30.0, 0.1, 9999.0)

	_lowGJumpTarget = _origJump * mult
	Game.SetGameSettingFloat("fJumpHeightMin", _lowGJumpTarget)

	If NoFallingDamageAbility && !akPlayer.HasSpell(NoFallingDamageAbility)
		akPlayer.AddSpell(NoFallingDamageAbility, false)
	EndIf

	_lowGActive = True
	_lowGEndRT = Utility.GetCurrentRealTime() + dur
	RegisterForSingleUpdate(0.5)
EndFunction

Function _StopLowG(Actor akPlayer)
	If _origJump > 0.0
		Game.SetGameSettingFloat("fJumpHeightMin", _origJump)
	EndIf

	If akPlayer && NoFallingDamageAbility && akPlayer.HasSpell(NoFallingDamageAbility)
		akPlayer.RemoveSpell(NoFallingDamageAbility)
	EndIf

	_lowGActive = False
	_lowGJumpTarget = 0.0
EndFunction

; =========================
; Stage 71 ó Backfire
; =========================
Function EnableBackfireTimed(Actor akPlayer)
	If akPlayer == None
		akPlayer = Game.GetPlayer()
	EndIf
	If akPlayer == None
		Debug.Trace("[TDL ChaosAlias ERROR] Backfire: player is None")
		Return
	EndIf

	If BackfireSpell == None
		Debug.Trace("[TDL ChaosAlias ERROR] BackfireSpell not set")
		Return
	EndIf

	Float dur = _GetFloatGV(Backfire_DurationGV, 60.0, 0.1, 9999.0)

	_backfireActive = True
	_backfireEndRT = Utility.GetCurrentRealTime() + dur
	_nextKnockbackRT = 0.0

	_RegisterAnimEvents(akPlayer)
	_EnsurePushMarker(akPlayer)
	_RegisterProjectileHit()

	RegisterForSingleUpdate(0.5)
EndFunction

Function _StopBackfire()
	_backfireActive = False
	_DestroyPushMarker()
	_UnregisterProjectileHit()
EndFunction

; =========================
; Shout knockback
; =========================
Function _DoShoutKnockbackSKSE(Actor p)
	If p == None
		Return
	EndIf

	_EnsurePushMarker(p)
	If _pushMarker == None
		Return
	EndIf

	Float del   = _GetFloatGV(ShoutPushDelayGV, 0.05, 0.0, 0.5)
	Float distF = _GetFloatGV(ShoutPushOriginDistGV, 70.0, 5.0, 250.0)
	Float upF   = _GetFloatGV(ShoutPushOriginUpGV, 25.0, -50.0, 150.0)
	Float force = _GetFloatGV(ShoutPushForceGV, 20.0, 0.0, 200.0)

	If force <= 0.0
		Return
	EndIf

	Float ang = p.GetAngleZ()
	Float fwdX = Math.Sin(ang)
	Float fwdY = Math.Cos(ang)

	Float mx = p.GetPositionX() + (fwdX * distF)
	Float my = p.GetPositionY() + (fwdY * distF)
	Float mz = p.GetPositionZ() + upF

	If del > 0.0
		Utility.Wait(del)
	EndIf

	_pushMarker.SetPosition(mx, my, mz)
	_pushMarker.PushActorAway(p, force)
EndFunction

; =========================
; Enemy knockback helpers
; =========================
Function _PushEnemyIfReady(Actor p, Actor a, Float force)
	If a == None || p == None || a.IsDead() || a == p || force <= 0.0
		Return
	EndIf

	If !_CooldownReady()
		Return
	EndIf
	_CommitCooldown()

	p.PushActorAway(a, force)
EndFunction

Function _TryKnockbackEnemiesSpell(Actor p)
	If p == None
		Return
	EndIf

	Float radius = _GetFloatGV(KnockbackRadiusGV, 900.0, 0.0, 20000.0)
	Float force  = _GetFloatGV(KnockbackForceGV, 25.0, 0.0, 200.0)
	If radius <= 0.0 || force <= 0.0
		Return
	EndIf

	Actor[] targets = PO3_SKSEFunctions.GetCombatTargets(p)
	If targets != None
		Int i = 0
		While i < targets.Length
			Actor a = targets[i]
			i += 1
			If a != None && !a.IsDead() && p.GetDistance(a) <= radius
				_PushEnemyIfReady(p, a, force)
				Return
			EndIf
		EndWhile
	EndIf

	ObjectReference cr = Game.GetCurrentCrosshairRef()
	Actor ca = cr as Actor
	If ca != None && !ca.IsDead() && p.GetDistance(ca) <= radius
		_PushEnemyIfReady(p, ca, force)
	EndIf
EndFunction

Function _TryKnockbackEnemyMeleeCrosshair(Actor p)
	If p == None
		Return
	EndIf

	Float force  = _GetFloatGV(KnockbackForceGV, 25.0, 0.0, 200.0)
	Float radius = _GetFloatGV(KnockbackMeleeRadiusGV, 200.0, 0.0, 800.0)
	Float cone   = _GetFloatGV(KnockbackMeleeConeDegGV, 55.0, 0.0, 180.0)
	Float mdel   = _GetFloatGV(KnockbackMeleeDelayGV, 0.10, 0.0, 0.5)

	If force <= 0.0 || radius <= 0.0
		Return
	EndIf

	ObjectReference cr = Game.GetCurrentCrosshairRef()
	Actor a = cr as Actor
	If a == None || a.IsDead()
		Return
	EndIf

	If p.GetDistance(a) > radius
		Return
	EndIf

	Float ha = p.GetHeadingAngle(a)
	If ha < 0.0
		ha = -ha
	EndIf
	If ha > cone
		Return
	EndIf

	If !_CooldownReady()
		Return
	EndIf
	_CommitCooldown()

	If mdel > 0.0
		Utility.Wait(mdel)
	EndIf

	If a != None && !a.IsDead()
		p.PushActorAway(a, force)
	EndIf
EndFunction

; =========================
; Animation events
; =========================
Function _RegisterAnimEvents(Actor p)
	If _animRegistered || p == None
		Return
	EndIf

	RegisterForAnimationEvent(p, "HitFrame")
	RegisterForAnimationEvent(p, "hitFrame")

	RegisterForAnimationEvent(p, "SpellCast")
	RegisterForAnimationEvent(p, "SpellFire")
	RegisterForAnimationEvent(p, "VoiceCast")
	RegisterForAnimationEvent(p, "VoiceFire")

	RegisterForAnimationEvent(p, "BeginCastRight")
	RegisterForAnimationEvent(p, "BeginCastLeft")
	RegisterForAnimationEvent(p, "BeginCastVoice")

	RegisterForAnimationEvent(p, "bowDraw")
	RegisterForAnimationEvent(p, "arrowRelease")
	RegisterForAnimationEvent(p, "bowReset")

	_animRegistered = True
EndFunction

Event OnProjectileHit(ObjectReference akTarget, Form akSource, Projectile akProjectile)
	If !_backfireActive
		Return
	EndIf

	Actor p = GetActorReference()
	If p == None
		p = Game.GetPlayer()
	EndIf
	If p == None
		Return
	EndIf

	Actor a = akTarget as Actor
	If a == None || a == p || a.IsDead()
		Return
	EndIf

	Float force = _GetFloatGV(KnockbackForceGV, 25.0, 0.0, 200.0)
	If force <= 0.0
		Return
	EndIf

	_PushEnemyIfReady(p, a, force)
EndEvent

Event OnAnimationEvent(ObjectReference akSource, String asEventName)
	If !_backfireActive
		Return
	EndIf

	Actor p = GetActorReference()
	If p == None
		p = Game.GetPlayer()
	EndIf
	If p == None || akSource != p
		Return
	EndIf

	If asEventName == "HitFrame" || asEventName == "hitFrame"
		_TryKnockbackEnemyMeleeCrosshair(p)

	ElseIf asEventName == "SpellCast" || asEventName == "SpellFire" || \
	       asEventName == "VoiceCast" || asEventName == "VoiceFire" || \
	       asEventName == "BeginCastRight" || asEventName == "BeginCastLeft" || \
	       asEventName == "BeginCastVoice"

		Form currentSpell = p.GetEquippedSpell(0)
		If !currentSpell
			currentSpell = p.GetEquippedSpell(1)
		EndIf
		If !currentSpell
			currentSpell = p.GetEquippedShout()
		EndIf

		If currentSpell
			_HandleSpellCast(currentSpell, p)
		EndIf

	ElseIf asEventName == "arrowRelease"
		_HandleBowAction(p)
	EndIf
EndEvent

Function _HandleBowAction(Actor p)
	If !_backfireActive || _suppressCast
		Return
	EndIf

	Weapon w = p.GetEquippedWeapon()
	If !w
		Return
	EndIf

	Int t = w.GetWeaponType()
	If t != 7 && t != 9
		Return
	EndIf

	Float bdel = _GetFloatGV(KnockbackBowDelayGV, 0.1, 0.0, 1.0)
	If bdel > 0.0
		Utility.Wait(bdel)
	EndIf

	_TryKnockbackEnemiesSpell(p)
EndFunction

Function _HandleSpellCast(Form akSpell, Actor p)
	If !_backfireActive || _suppressCast
		Return
	EndIf

	Spell s = akSpell as Spell
	If s == None || s == BackfireSpell
		Return
	EndIf

	Bool isShout = false
	If MagicShoutKW != None
		isShout = s.HasKeyword(MagicShoutKW)
	EndIf

	If !isShout
		Float sdel = _GetFloatGV(KnockbackSpellDelayGV, 0.15, 0.0, 1.5)
		If sdel > 0.0
			Utility.Wait(sdel)
		EndIf
		_TryKnockbackEnemiesSpell(p)
	EndIf

	Float chance = _GetFloatGV(Backfire_ChanceGV, 20.0, 0.0, 100.0)
	If Utility.RandomFloat(0.0, 100.0) > chance
		Return
	EndIf

	_suppressCast = True
	BackfireSpell.Cast(p, p)

	If isShout
		_DoShoutKnockbackSKSE(p)
	EndIf
	_suppressCast = False

	If ChaosVFX
		ChaosVFX.Play(p, 1.2)
	EndIf
	Game.ShakeCamera(p, 0.8, 0.4)
EndFunction

Event OnUpdate()
	Float now = Utility.GetCurrentRealTime()

	Actor p = GetActorReference()
	If p == None
		p = Game.GetPlayer()
	EndIf

	If _lowGActive && _lowGJumpTarget > 0.0
		If Game.GetGameSettingFloat("fJumpHeightMin") != _lowGJumpTarget
			Game.SetGameSettingFloat("fJumpHeightMin", _lowGJumpTarget)
		EndIf
	EndIf

	If _lowGActive && now >= _lowGEndRT
		_StopLowG(p)
	EndIf

	If _backfireActive && now >= _backfireEndRT
		_StopBackfire()
	EndIf

	If _lowGActive || _backfireActive
		RegisterForSingleUpdate(0.5)
	EndIf
EndEvent

Event OnReset()
	Actor p = GetActorReference()
	If p == None
		p = Game.GetPlayer()
	EndIf

	If _origJump > 0.0
		Game.SetGameSettingFloat("fJumpHeightMin", _origJump)
	EndIf

	If p && NoFallingDamageAbility && p.HasSpell(NoFallingDamageAbility)
		p.RemoveSpell(NoFallingDamageAbility)
	EndIf

	_nextKnockbackRT = 0.0
	_DestroyPushMarker()
	_UnregisterProjectileHit()

	_lowGActive = False
	_backfireActive = False
	_lowGJumpTarget = 0.0
EndEvent