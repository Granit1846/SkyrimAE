Scriptname TDL_WrathOfGod extends Quest

; =====================================================
; DEBUG
; =====================================================
GlobalVariable Property TDL_DebugEnabled Auto

; =====================================================
; CONTENT
; =====================================================
FormList Property TDL_Storm1 Auto
FormList Property TDL_Fire Auto
FormList Property TDL_Frost Auto

Form Property MarkerBase Auto ; XMarker

; =====================================================
; GLOBAL CONFIG
; =====================================================
GlobalVariable Property Wrath_TotalBurstsGV Auto
GlobalVariable Property Wrath_EffectIntervalGV Auto
GlobalVariable Property Wrath_RadiusGV Auto
GlobalVariable Property Wrath_ZOffsetGV Auto

GlobalVariable Property Wrath_DamageMinGV Auto
GlobalVariable Property Wrath_DamageMaxGV Auto

GlobalVariable Property Wrath_FireDamageMultGV Auto
GlobalVariable Property Wrath_StormMagickaMultGV Auto
GlobalVariable Property Wrath_FrostStaminaMultGV Auto

GlobalVariable Property Wrath_ShakeChanceGV Auto
GlobalVariable Property Wrath_ShakeStrengthGV Auto
GlobalVariable Property Wrath_ShakeDurationGV Auto

GlobalVariable Property Wrath_LevelScaleGV Auto
GlobalVariable Property Wrath_LevelCapGV Auto

; =====================================================
; FALLBACKS
; =====================================================
Int   Property TotalBurstsFallback = 6 Auto
Float Property EffectIntervalFallback = 0.4 Auto
Float Property RadiusFallback = 300.0 Auto
Float Property ZOffsetFallback = 50.0 Auto

Float Property DamageMinFallback = 5.0 Auto
Float Property DamageMaxFallback = 15.0 Auto

; =====================================================
; ENTRY
; =====================================================
Bool Function RunStage(Int aiStage, Actor PlayerRef)
	If aiStage == 11
		Return RunElement(1, PlayerRef)
	ElseIf aiStage == 12
		Return RunElement(2, PlayerRef)
	ElseIf aiStage == 13
		Return RunElement(3, PlayerRef)
	EndIf

	_Notify("TDL Wrath unknown stage " + aiStage)
	Return False
EndFunction

; =====================================================
; CORE
; =====================================================
Bool Function RunElement(Int aiElement, Actor PlayerRef)
	FormList listRef = None
	String name = ""

	If aiElement == 1
		listRef = TDL_Storm1
		name = "Storm"
	ElseIf aiElement == 2
		listRef = TDL_Fire
		name = "Fire"
	ElseIf aiElement == 3
		listRef = TDL_Frost
		name = "Frost"
	Else
		_Notify("TDL Wrath unknown element")
		Return False
	EndIf

	If !PlayerRef || !MarkerBase || !listRef || listRef.GetSize() <= 0
		_Notify("TDL Wrath setup error (" + name + ")")
		Return False
	EndIf

	; ===== READ GLOBALS (ONCE) =====

	Int totalBursts = TotalBurstsFallback
	If Wrath_TotalBurstsGV != None
		totalBursts = Wrath_TotalBurstsGV.GetValueInt()
	EndIf
	If totalBursts < 1
		totalBursts = 1
	EndIf

	Float interval = EffectIntervalFallback
	If Wrath_EffectIntervalGV != None
		interval = Wrath_EffectIntervalGV.GetValue()
	EndIf
	If interval < 0.05
		interval = 0.05
	EndIf

	Float radius = RadiusFallback
	If Wrath_RadiusGV != None
		radius = Wrath_RadiusGV.GetValue()
	EndIf
	If radius < 50.0
		radius = 50.0
	EndIf

	Float zOff = ZOffsetFallback
	If Wrath_ZOffsetGV != None
		zOff = Wrath_ZOffsetGV.GetValue()
	EndIf

	Float dmgMin = DamageMinFallback
	Float dmgMax = DamageMaxFallback
	If Wrath_DamageMinGV != None
		dmgMin = Wrath_DamageMinGV.GetValue()
	EndIf
	If Wrath_DamageMaxGV != None
		dmgMax = Wrath_DamageMaxGV.GetValue()
	EndIf
	If dmgMax < dmgMin
		dmgMax = dmgMin
	EndIf

	Float fireMult = 1.0
	If Wrath_FireDamageMultGV != None
		fireMult = Wrath_FireDamageMultGV.GetValue()
	EndIf
	If fireMult < 0.0
		fireMult = 0.0
	EndIf

	Float stormMagMult = 1.0
	If Wrath_StormMagickaMultGV != None
		stormMagMult = Wrath_StormMagickaMultGV.GetValue()
	EndIf
	If stormMagMult < 0.0
		stormMagMult = 0.0
	EndIf

	Float frostStaMult = 1.0
	If Wrath_FrostStaminaMultGV != None
		frostStaMult = Wrath_FrostStaminaMultGV.GetValue()
	EndIf
	If frostStaMult < 0.0
		frostStaMult = 0.0
	EndIf

	Int shakeChance = 0
	If Wrath_ShakeChanceGV != None
		shakeChance = Wrath_ShakeChanceGV.GetValueInt()
	EndIf
	If shakeChance < 0
		shakeChance = 0
	ElseIf shakeChance > 100
		shakeChance = 100
	EndIf

	Float shakeStrength = 0.0
	If Wrath_ShakeStrengthGV != None
		shakeStrength = Wrath_ShakeStrengthGV.GetValue()
	EndIf

	Float shakeDuration = 0.0
	If Wrath_ShakeDurationGV != None
		shakeDuration = Wrath_ShakeDurationGV.GetValue()
	EndIf

	; ===== LEVEL SCALING =====
	Float levelScale = 0.0
	If Wrath_LevelScaleGV != None
		levelScale = Wrath_LevelScaleGV.GetValue()
	EndIf

	Float levelCap = 3.0
	If Wrath_LevelCapGV != None
		levelCap = Wrath_LevelCapGV.GetValue()
	EndIf

	Int playerLevel = PlayerRef.GetLevel()
	Float levelMult = 1.0 + (playerLevel * levelScale)
	If levelMult > levelCap
		levelMult = levelCap
	EndIf

	; ===== EXECUTION =====
	Int i = 0
	While i < totalBursts
		Float offsetX = Utility.RandomFloat(-radius, radius)
		Float offsetY = Utility.RandomFloat(-radius, radius)

		ObjectReference marker = PlayerRef.PlaceAtMe(MarkerBase, 1)
		If marker
			marker.MoveTo(PlayerRef, offsetX, offsetY, zOff)

			Int idx = Utility.RandomInt(0, listRef.GetSize() - 1)
			Form f = listRef.GetAt(idx)

			Spell sp = f as Spell
			Explosion ex = f as Explosion

			If sp
				sp.Cast(PlayerRef, marker)
			ElseIf ex
				marker.PlaceAtMe(ex, 1)
			EndIf

			Float baseDamage = Utility.RandomFloat(dmgMin, dmgMax)

			Float dist = marker.GetDistance(PlayerRef)
			Float t = dist / radius
			If t > 1.0
				t = 1.0
			EndIf

			Float minMult = 0.08
			Float coreFalloff = 1.0 - t

			; === FALL OFF CURVES ===
			If aiElement == 2
				; Fire Ч квадратична€
				coreFalloff = coreFalloff * coreFalloff
			EndIf

			Float falloffMult = minMult + (1.0 - minMult) * coreFalloff
			Float finalDamage = baseDamage * falloffMult * levelMult

			If aiElement == 2
				finalDamage = finalDamage * fireMult
			EndIf

			PlayerRef.DamageAV("Health", finalDamage)

			If aiElement == 1
				PlayerRef.DamageAV("Magicka", finalDamage * stormMagMult)
			ElseIf aiElement == 3
				PlayerRef.DamageAV("Stamina", finalDamage * frostStaMult)
			EndIf

			If shakeChance > 0 && shakeStrength > 0.0 && shakeDuration > 0.0
				If Utility.RandomInt(1, 100) <= shakeChance
					Game.ShakeCamera(PlayerRef, shakeStrength, shakeDuration)
				EndIf
			EndIf

			marker.Disable()
			marker.Delete()
		EndIf

		Utility.Wait(interval)
		i += 1
	EndWhile

	_Notify("TDL Wrath " + name + " done")
	Return True
EndFunction

; =====================================================
; UTILS
; =====================================================
Function _Notify(String asText)
	If !TDL_DebugEnabled || (TDL_DebugEnabled.GetValueInt() == 1)
		Debug.Notification(asText)
	EndIf
EndFunction