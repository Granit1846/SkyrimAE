; =====================================================
; TDL_Weather
; =====================================================
Scriptname TDL_Weather extends Quest

Weather Property WeatherClear Auto
Weather Property WeatherRain Auto
Weather Property WeatherSnow Auto
Weather Property WeatherStorm Auto
Weather Property WeatherFog Auto

Spell Property WeatherClearSpell Auto
Spell Property WeatherRainSpell Auto
Spell Property WeatherSnowSpell Auto
Spell Property WeatherStormSpell Auto
Spell Property WeatherFogSpell Auto

Spell _activeSpell = None

Float _baseSpeed = 0.0
Float _weatherSpeedDelta = 0.0
Bool  _speedActive = false

Float _weatherResetAt = 0.0
Bool  _autoResetActive = false

Bool Function RunStage(Int aiStage, Actor playerRef)
	If !playerRef
		playerRef = Game.GetPlayer()
	EndIf
	If !playerRef
		Debug.Trace("[TDL Weather ERROR] PlayerRef None")
		Return False
	EndIf

	If aiStage == 119
		_ResetAll(playerRef)
		Return True
	EndIf

	If aiStage == 110
		Return _ApplyPreset(playerRef, WeatherClear, WeatherClearSpell, 0.0)
	ElseIf aiStage == 111
		Return _ApplyPreset(playerRef, WeatherRain, WeatherRainSpell, -10.0)
	ElseIf aiStage == 112
		Return _ApplyPreset(playerRef, WeatherSnow, WeatherSnowSpell, -15.0)
	ElseIf aiStage == 113
		Return _ApplyPreset(playerRef, WeatherStorm, WeatherStormSpell, 10.0)
	ElseIf aiStage == 114
		Return _ApplyPreset(playerRef, WeatherFog, WeatherFogSpell, 5.0)
	EndIf

	Debug.Trace("[TDL Weather ERROR] Unknown stage " + aiStage)
	Return False
EndFunction

Bool Function _ApplyPreset(Actor p, Weather w, Spell sp, Float speedDelta)
	If p.IsInInterior()
		Return False
	EndIf

	If w == None
		Debug.Trace("[TDL Weather ERROR] Weather is None")
		Return False
	EndIf

	_ResetWeatherSpeed(p)
	_RemoveActiveSpell(p)

	w.SetActive(true)

	If sp
		p.AddSpell(sp, false)
		_activeSpell = sp
	EndIf

	If speedDelta != 0.0
		_ApplyWeatherSpeed(p, speedDelta)
	EndIf

	_weatherResetAt = Utility.GetCurrentGameTime() + 0.125
	_autoResetActive = true
	RegisterForSingleUpdate(1.0)

	Return True
EndFunction

Function _CaptureBaseSpeed(Actor p)
	If _baseSpeed <= 0.0
		Float cur = p.GetActorValue("SpeedMult")
		If cur < 1.0
			cur = 100.0
		EndIf
		_baseSpeed = cur
	EndIf
EndFunction

Function _ApplyWeatherSpeed(Actor p, Float delta)
	_CaptureBaseSpeed(p)
	_weatherSpeedDelta = delta
	_speedActive = true

	Float target = _baseSpeed + _weatherSpeedDelta
	If target < 1.0
		target = 1.0
	EndIf

	p.SetActorValue("SpeedMult", target)
EndFunction

Function _ResetWeatherSpeed(Actor p)
	If _speedActive && _baseSpeed > 0.0
		p.SetActorValue("SpeedMult", _baseSpeed)
	EndIf

	_weatherSpeedDelta = 0.0
	_speedActive = false
EndFunction

Function _RemoveActiveSpell(Actor p)
	If _activeSpell && p.HasSpell(_activeSpell)
		p.RemoveSpell(_activeSpell)
	EndIf
	_activeSpell = None
EndFunction

Function _ResetAll(Actor p)
	_ResetWeatherSpeed(p)
	_RemoveActiveSpell(p)
	Weather.ReleaseOverride()

	_baseSpeed = 0.0
	_weatherSpeedDelta = 0.0
	_speedActive = false
	_weatherResetAt = 0.0
	_autoResetActive = false
EndFunction

Event OnUpdate()
	Actor p = Game.GetPlayer()
	If !p
		Return
	EndIf

	If _speedActive
		Float expected = _baseSpeed + _weatherSpeedDelta
		If expected < 1.0
			expected = 1.0
		EndIf

		If p.GetActorValue("SpeedMult") != expected
			p.SetActorValue("SpeedMult", expected)
		EndIf
	EndIf

	If _autoResetActive
		If Utility.GetCurrentGameTime() >= _weatherResetAt
			_ResetAll(p)
			Return
		EndIf
	EndIf

	If _speedActive || _autoResetActive
		RegisterForSingleUpdate(1.0)
	EndIf
EndEvent