Scriptname TDL_Comedy extends Quest

; =====================================================
; TDL_Comedy
; Status: STABLE / DONE (Stages 50–53)
; =====================================================

; =====================================================
; DEBUG
; =====================================================
GlobalVariable Property TDL_DebugEnabled Auto
Function _Notify(String msg)
	If !TDL_DebugEnabled || TDL_DebugEnabled.GetValueInt() == 1
		Debug.Notification(msg)
	EndIf
EndFunction

; ======================= STAGE 50 =====================
ActorBase Property FakeHeroBase Auto

GlobalVariable Property FakeHeroDuration Auto
GlobalVariable Property FakeHeroActionInterval Auto
GlobalVariable Property FakeHeroDamageMult Auto
GlobalVariable Property FakeHeroPushForce Auto
GlobalVariable Property FakeHeroShoutChance Auto
GlobalVariable Property FakeHeroSpellChance Auto

FormList Property FakeHeroShouts Auto
FormList Property FakeHeroSpells Auto

Actor _hero50
Bool _stage50Active = false
Bool _stage50Initialized = false
Float _stage50EndTime = 0.0
Float _stage50NextAction = 0.0

; =====================================================
; ======================= STAGE 51 =====================
; =====================================================
ActorBase Property TDL_ShadowHunterBase Auto
ImageSpaceModifier Property HorrorIMOD_Exterior Auto
ImageSpaceModifier Property HorrorIMOD_Interior Auto

MusicType Property HorrorMusic Auto

GlobalVariable Property HorrorTeleportDistance Auto
GlobalVariable Property HorrorSpawnDistance Auto
GlobalVariable Property HorrorMaxDistance Auto
GlobalVariable Property HorrorHealth Auto
GlobalVariable Property HorrorDuration Auto

Float _nextMusicTime = 0.0
Float _musicTotalDuration = 120.0  ; 2 минуты = 120 секунд
Float _musicInterval = 20.0        ; Интервал повторения

Actor _horrorHunter
Bool _stage51Active = false
Float _stage51EndTime = 0.0
ImageSpaceModifier _activeHorrorIMOD
Bool _lastWasInterior = false

; =====================================================
; ======================= STAGE 52 =====================
; =====================================================
Actor Property PlayerRef Auto

GlobalVariable Property ArenaWaves Auto
GlobalVariable Property ArenaWaveInterval Auto
GlobalVariable Property ArenaSpawnRadius Auto
GlobalVariable Property ArenaPerWave Auto
GlobalVariable Property ArenaTimeoutMinutes Auto

Message Property ArenaRewardMessage_Normal Auto
Message Property ArenaRewardMessage_Final Auto
Message Property TDL_ArenaTimeoutPenaltyMsg Auto

FormList Property TDL_EnemyLow Auto
FormList Property TDL_EnemyMedium Auto
FormList Property TDL_EnemyHard Auto

Spell Property TDL_ArenaPenaltySpellTest Auto

Bool _stage52Active = false
Int _arenaState = 0 ; 1=wave, 2=wait
Int _arenaCurrentWave = 0
Float _arenaStateTime = 0.0

Actor[] _arenaWaveEnemies
Int _arenaWaveCount = 0

Actor[] _arenaAllEnemies
Int _arenaAllCount = 0

Bool _arenaCleanupPending = false
Float _arenaCorpseCleanupAt = 0.0
Float _arenaTimeoutAt = 0.0

; =====================================================
; ======================= STAGE 53 =====================
; =====================================================
FormList Property EscortAnimals Auto
FormList Property EscortRewardChests Auto
GlobalVariable Property EscortDuration Auto

Quest Property MainControllerQuest Auto
ReferenceAlias Property EscortTargetAlias Auto ; Quest Marker alias
ActorBase Property EscortBanditBase Auto ; EncBandit02Boss2HNordM (0003DEE4)
; Objective index in CK: 530

Actor[] _escortBandits
Int _escortBanditCount = 0
Bool _escortBanditLoopActive = false

Bool _stage53Active = false

Actor _escortActor
Float _escortEndTime = 0.0
Float _escortIgnoreSince = 0.0

ObjectReference _escortChest
Int _stage53FailReason = 0 ; 1=dead, 2=distance

Bool _pendingWrath = false

; =====================================================
; ENTRY POINT
; =====================================================
Bool Function RunStage(Int aiStage, Actor playerRef)
	If !playerRef
		playerRef = Game.GetPlayer()
	EndIf
	If !playerRef
		Return False
	EndIf

	If aiStage == 50
		Return _StartStage50(playerRef)
	ElseIf aiStage == 51
		Return _StartStage51(playerRef)
	ElseIf aiStage == 52
		Return _StartStage52(playerRef)
	ElseIf aiStage == 53
		Return _StartStage53(playerRef)
	EndIf

	Return False
EndFunction

; =====================================================
; ======================= STAGE 50 =====================
; =====================================================
Bool Function _StartStage50(Actor p)
	If _stage50Initialized
		Float dur = 120.0
		If FakeHeroDuration
			dur = FakeHeroDuration.GetValue()
		EndIf
		_stage50EndTime = Utility.GetCurrentRealTime() + dur
		_Notify("Fake Hero timer refreshed")
		Return True
	EndIf

	_hero50 = p.PlaceAtMe(FakeHeroBase, 1) as Actor
	If !_hero50
		Return False
	EndIf

	If FakeHeroDamageMult
		_hero50.ModActorValue("AttackDamageMult", FakeHeroDamageMult.GetValue())
	EndIf

	Float dur2 = 120.0
	If FakeHeroDuration
		dur2 = FakeHeroDuration.GetValue()
	EndIf

	_stage50Initialized = true
	_stage50Active = true
	_stage50EndTime = Utility.GetCurrentRealTime() + dur2
	_stage50NextAction = Utility.GetCurrentRealTime()

	RegisterForSingleUpdate(0.5)
	Return True
EndFunction

Function _UpdateStage50()
	If !_hero50
		_EndStage50()
		Return
	EndIf

	Float now = Utility.GetCurrentRealTime()
	If now < _stage50NextAction
		Return
	EndIf

	Float interval = 3.0
	If FakeHeroActionInterval
		interval = FakeHeroActionInterval.GetValue()
	EndIf
	_stage50NextAction = now + interval

	Actor p = Game.GetPlayer()
	If !p
		Return
	EndIf

	_hero50.StartCombat(p)

	If FakeHeroShouts && FakeHeroShoutChance && Utility.RandomFloat(0.0, 100.0) <= FakeHeroShoutChance.GetValue()
		Int sz = FakeHeroShouts.GetSize()
		If sz > 0
			Shout sh = FakeHeroShouts.GetAt(Utility.RandomInt(0, sz - 1)) as Shout
			If sh
				_hero50.AddShout(sh)
			EndIf
		EndIf
	EndIf

	If FakeHeroSpells && FakeHeroSpellChance && Utility.RandomFloat(0.0, 100.0) <= FakeHeroSpellChance.GetValue()
		Int sz2 = FakeHeroSpells.GetSize()
		If sz2 > 0
			Spell sp = FakeHeroSpells.GetAt(Utility.RandomInt(0, sz2 - 1)) as Spell
			If sp && !_hero50.HasSpell(sp)
				_hero50.AddSpell(sp)
				_hero50.EquipSpell(sp, 0)
			EndIf
		EndIf
	EndIf

	If FakeHeroPushForce && Utility.RandomFloat(0.0, 100.0) <= FakeHeroPushForce.GetValue()
		p.PushActorAway(_hero50, FakeHeroPushForce.GetValue())
	EndIf
EndFunction

Function _EndStage50()
	If _hero50
		_hero50.Disable()
		_hero50.Delete()
	EndIf
	_hero50 = None
	_stage50Active = false
	_stage50Initialized = false
EndFunction

; =====================================================
; ======================= STAGE 51 =====================
; =====================================================
Bool Function _StartStage51(Actor p)
	If _stage51Active && _horrorHunter
		Float dur = 120.0
		If HorrorDuration
			dur = HorrorDuration.GetValue()
		EndIf
		_stage51EndTime = Utility.GetCurrentRealTime() + dur
		Return True
	EndIf

	Float spawnDist = 800.0
	If HorrorSpawnDistance
		spawnDist = HorrorSpawnDistance.GetValue()
	EndIf

	_horrorHunter = p.PlaceAtMe(TDL_ShadowHunterBase, 1) as Actor
	If !_horrorHunter
		Return False
	EndIf

	_PositionHorrorHunter(p, spawnDist)

	If HorrorHealth
		_horrorHunter.SetActorValue("Health", HorrorHealth.GetValue())
	EndIf

	Float dur = 120.0
	If HorrorDuration
		dur = HorrorDuration.GetValue()
	EndIf

	_stage51EndTime = Utility.GetCurrentRealTime() + dur
	_stage51Active = true

	_lastWasInterior = p.IsInInterior()
	_ApplyHorrorIMOD(p)

	; Настроить музыку
	_AddHorrorMusic()
	_nextMusicTime = Utility.GetCurrentRealTime() + _musicInterval  ; Первый повтор через 20 сек

	RegisterForSingleUpdate(0.5)
	Return True
EndFunction

Function _UpdateHorrorMusic()
    Float now = Utility.GetCurrentRealTime()
    
    ; Если музыкальный период еще не истек
    If now < (_stage51EndTime - _musicTotalDuration)
        ; Если пришло время для следующего воспроизведения
        If now >= _nextMusicTime
            _RemoveHorrorMusic()  ; Сначала остановить текущую
            _AddHorrorMusic()     ; Запустить заново
            _nextMusicTime = now + _musicInterval  ; Запланировать следующее
        EndIf
    EndIf
EndFunction

Function _AddHorrorMusic()
    If HorrorMusic
        HorrorMusic.Add()
    EndIf
EndFunction

Function _RemoveHorrorMusic()
    If HorrorMusic
        HorrorMusic.Remove()
    EndIf
EndFunction

Function _UpdateStage51()
	Actor p = Game.GetPlayer()
	If !_horrorHunter || !p
		_EndStage51()
		Return
	EndIf

	If Utility.GetCurrentRealTime() >= _stage51EndTime
		_EndStage51()
		Return
	EndIf

	If p.IsInInterior() != _lastWasInterior
		_ApplyHorrorIMOD(p)
	EndIf

	Float maxD = 3000.0
	If HorrorMaxDistance
		maxD = HorrorMaxDistance.GetValue()
	EndIf

	If _horrorHunter.GetDistance(p) > maxD
		Float tp = 600.0
		If HorrorTeleportDistance
			tp = HorrorTeleportDistance.GetValue()
		EndIf
		_PositionHorrorHunter(p, tp)
	EndIf

	_horrorHunter.StartCombat(p)
	
	; Обновить музыку (проверить, нужно ли перезапустить)
	_UpdateHorrorMusic()
	
	RegisterForSingleUpdate(0.5)
EndFunction

Function _ApplyHorrorIMOD(Actor p)
	If _activeHorrorIMOD
		_activeHorrorIMOD.Remove()
	EndIf

	If p.IsInInterior()
		_activeHorrorIMOD = HorrorIMOD_Interior
	Else
		_activeHorrorIMOD = HorrorIMOD_Exterior
	EndIf

	If _activeHorrorIMOD
		_activeHorrorIMOD.Apply()
	EndIf

	_lastWasInterior = p.IsInInterior()
EndFunction

Function _EndStage51()
	_RemoveHorrorMusic()
	_nextMusicTime = 0.0  ; Сбросить таймер

	If _activeHorrorIMOD
		_activeHorrorIMOD.Remove()
	EndIf
	_activeHorrorIMOD = None
	_lastWasInterior = false

	If _horrorHunter
		_horrorHunter.Disable()
		_horrorHunter.Delete()
	EndIf

	_horrorHunter = None
	_stage51Active = false
EndFunction

Function _PositionHorrorHunter(Actor p, Float dist)
	Int r = Utility.RandomInt(0, 3)
	If r == 0
		_horrorHunter.MoveTo(p, dist, 0, 0)
	ElseIf r == 1
		_horrorHunter.MoveTo(p, -dist, 0, 0)
	ElseIf r == 2
		_horrorHunter.MoveTo(p, 0, dist, 0)
	Else
		_horrorHunter.MoveTo(p, 0, -dist, 0)
	EndIf
EndFunction

; =====================================================
; ======================= STAGE 52 =====================
; NOTE: Arena stage intentionally has no Quest Objectives.
; =====================================================
Bool Function _StartStage52(Actor p)
	If _stage52Active
		Return False
	EndIf

	If !p
		Return False
	EndIf

	; Safety: если прошлый забег завис/не дочистился — принудительно чистим
	If _arenaAllCount > 0
		_CleanupArenaAll()
	EndIf

	_stage52Active = true
	_arenaState = 1
	_arenaCurrentWave = 1
	_arenaStateTime = 0.0

	_arenaWaveEnemies = new Actor[32]
	_arenaWaveCount = 0

	_arenaAllEnemies = new Actor[128]
	_arenaAllCount = 0

	_arenaCleanupPending = false
	_arenaCorpseCleanupAt = 0.0

	Float now = Utility.GetCurrentRealTime()

	Float tmin = 0.0
	If !ArenaTimeoutMinutes
		_Notify("Stage52 ERROR: ArenaTimeoutMinutes property is None")
		Return False
	EndIf
	tmin = ArenaTimeoutMinutes.GetValue()

	If tmin < 1.0
		tmin = 1.0
	EndIf

	_arenaTimeoutAt = now + (tmin * 60.0)

	_SpawnArenaWave(p, 1)

	; защита от "нулевой волны" (иначе _AllArenaWaveDead() вернёт True и выдаст награду сразу)
	If _arenaWaveCount <= 0
		_CleanupArenaAll()
		_FinalizeStage52()
		Return False
	EndIf

	RegisterForSingleUpdate(0.5)
	Return True
EndFunction

Function _UpdateStage52()
	Actor p = Game.GetPlayer()
	If !p
		_HandleArenaTimeout()
		Return
	EndIf

	Float now = Utility.GetCurrentRealTime()

	; Таймаут: жёсткая очистка и сброс Stage 52 (без penalty/MessageBox)
	If _arenaTimeoutAt > 0.0 && now >= _arenaTimeoutAt
		_HandleArenaTimeout()
		Return
	EndIf

	If _arenaState == 1
		If !_AllArenaWaveDead()
			Return
		EndIf

		Int maxW = 3
		If ArenaWaves
			maxW = ArenaWaves.GetValueInt()
		EndIf
		If maxW < 1
			maxW = 1
		EndIf

		If _arenaCurrentWave >= maxW
			_GiveArenaReward_Final(p)
			_ShowArenaRewardMessage_Final()

			; после финала чистим всех противников (живых и трупы) с задержкой
			_arenaCleanupPending = true
			_arenaCorpseCleanupAt = now + 60.0

			_FinalizeStage52()
			Return
		Else
			_GiveArenaReward_Normal(p)
			_ShowArenaRewardMessage_Normal()

			_arenaState = 2
			_arenaStateTime = now
			Return
		EndIf
	EndIf

	If _arenaState == 2
		Float iv = 3.0
		If ArenaWaveInterval
			iv = ArenaWaveInterval.GetValue()
		EndIf
		If iv < 0.5
			iv = 0.5
		EndIf

		If now < (_arenaStateTime + iv)
			Return
		EndIf

		_arenaCurrentWave += 1
		_arenaState = 1

		_SpawnArenaWave(p, _arenaCurrentWave)

		; защита от "нулевой волны" на середине забега
		If _arenaWaveCount <= 0
			_HandleArenaTimeout()
			Return
		EndIf
	EndIf
EndFunction

Function _SpawnArenaWave(Actor p, Int wave)
	FormList lst
	Int t = wave % 3
	If t == 1
		lst = TDL_EnemyLow
	ElseIf t == 2
		lst = TDL_EnemyMedium
	Else
		lst = TDL_EnemyHard
	EndIf

	_arenaWaveCount = 0

	If !lst || lst.GetSize() <= 0
		Return
	EndIf

	Float r = 800.0
	If ArenaSpawnRadius
		r = ArenaSpawnRadius.GetValue()
	EndIf
	If r < 100.0
		r = 100.0
	EndIf

	Int cnt = 3
	If ArenaPerWave
		cnt = ArenaPerWave.GetValueInt()
	EndIf
	If cnt < 1
		cnt = 1
	EndIf
	If cnt > 20
		cnt = 20
	EndIf

	Int i = 0
	While i < cnt
		ActorBase ab = lst.GetAt(Utility.RandomInt(0, lst.GetSize() - 1)) as ActorBase
		If ab
			Actor a = p.PlaceAtMe(ab, 1) as Actor
			If a
				a.MoveTo(p, Utility.RandomFloat(-r, r), Utility.RandomFloat(-r, r), 0)
				a.StartCombat(p)

				If _arenaWaveCount < 32
					_arenaWaveEnemies[_arenaWaveCount] = a
					_arenaWaveCount += 1
				EndIf

				If _arenaAllCount < 128
					_arenaAllEnemies[_arenaAllCount] = a
					_arenaAllCount += 1
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
EndFunction

Function _GiveArenaReward_Normal(Actor p)
	p.AddItem(Game.GetFormFromFile(0x00039BE5, "Skyrim.esm"), 1, True)
	p.AddItem(Game.GetFormFromFile(0x00039BE7, "Skyrim.esm"), 1, True)
	p.AddItem(Game.GetFormFromFile(0x00039CF3, "Skyrim.esm"), 1, True)
	p.AddItem(Game.GetFormFromFile(0x0000000F, "Skyrim.esm"), 750, True)
EndFunction

Function _GiveArenaReward_Final(Actor p)
	p.AddItem(Game.GetFormFromFile(0x00039BE5, "Skyrim.esm"), 1, True)
	p.AddItem(Game.GetFormFromFile(0x00039BE7, "Skyrim.esm"), 1, True)
	p.AddItem(Game.GetFormFromFile(0x00039CF3, "Skyrim.esm"), 1, True)
	p.AddItem(Game.GetFormFromFile(0x0000000F, "Skyrim.esm"), 1500, True)
EndFunction

Function _ShowArenaRewardMessage_Normal()
	If ArenaRewardMessage_Normal
		ArenaRewardMessage_Normal.Show()
	EndIf
EndFunction

Function _ShowArenaRewardMessage_Final()
	If ArenaRewardMessage_Final
		ArenaRewardMessage_Final.Show()
	EndIf
EndFunction

Bool Function _AllArenaWaveDead()
	Int i = 0
	While i < _arenaWaveCount
		If _arenaWaveEnemies[i] && !_arenaWaveEnemies[i].IsDead()
			Return False
		EndIf
		i += 1
	EndWhile
	Return True
EndFunction

Function _FinalizeStage52()
	_stage52Active = false
	_arenaState = 0
	_arenaCurrentWave = 0
EndFunction

Function _CleanupArenaCorpses()
	Int i = 0
	While i < _arenaAllCount
		Actor a = _arenaAllEnemies[i]
		If a
			a.Disable()
			a.Delete()
		EndIf
		i += 1
	EndWhile

	_arenaAllCount = 0
	_arenaWaveCount = 0
	_arenaCleanupPending = false
	_arenaCorpseCleanupAt = 0.0
EndFunction

Function _CleanupArenaAll()
	Int i = 0
	While i < _arenaAllCount
		Actor a = _arenaAllEnemies[i]
		If a
			a.Disable()
			a.Delete()
		EndIf
		i += 1
	EndWhile

	_arenaAllCount = 0
	_arenaWaveCount = 0
	_arenaCleanupPending = false
	_arenaCorpseCleanupAt = 0.0
EndFunction

Function _HandleArenaTimeout()
	; жёсткая очистка (живые + трупы) и сброс Stage 52 (без penalty/MessageBox)
	_CleanupArenaAll()
	_FinalizeStage52()
	_arenaTimeoutAt = 0.0
	
	If TDL_ArenaTimeoutPenaltyMsg
		TDL_ArenaTimeoutPenaltyMsg.Show()
	EndIf

	If TDL_ArenaPenaltySpellTest 
		TDL_ArenaPenaltySpellTest.Cast(PlayerRef, PlayerRef)
	EndIf
EndFunction



; =====================================================
; ======================= STAGE 53 =====================
; =====================================================
Bool Function _StartStage53(Actor p)
	If EscortAnimals == None || EscortAnimals.GetSize() <= 0
		_Notify("TDL Comedy: EscortAnimals empty")
		Return False
	EndIf
	If EscortRewardChests == None || EscortRewardChests.GetSize() <= 0
		_Notify("TDL Comedy: EscortRewardChests empty")
		Return False
	EndIf

	_CleanupStage53_Internal()

	ActorBase ab = EscortAnimals.GetAt(Utility.RandomInt(0, EscortAnimals.GetSize() - 1)) as ActorBase
	If !ab
		Return False
	EndIf

	_escortActor = p.PlaceAtMe(ab, 1) as Actor
	If !_escortActor
		Return False
	EndIf

	_escortActor.SetActorValue("Aggression", 0)
	_escortActor.SetActorValue("Confidence", 0)
	_escortActor.SetActorValue("Health", 300)
	_escortActor.MoveTo(p, 150.0, 0.0, 0.0)

	If EscortTargetAlias
		EscortTargetAlias.ForceRefTo(_escortActor)
	EndIf

	SetObjectiveDisplayed(530, true)

	Float dur = 120.0
	If EscortDuration
		dur = EscortDuration.GetValue()
	EndIf

	_stage53FailReason = 0
	_escortIgnoreSince = 0.0
	_escortEndTime = Utility.GetCurrentRealTime() + dur
	_stage53Active = true

	_Notify("Сопроводите существо и не отходите от него.")
	RegisterForSingleUpdate(1.0)
	
	_escortBanditLoopActive = true
	_escortBandits = new Actor[128]
	_escortBanditCount = 0
	_StartEscortBanditLoop()
	Return True
EndFunction

Function _StartEscortBanditLoop()
	While _escortBanditLoopActive && _stage53Active && _escortActor
		Utility.Wait(35.0)

		If !_escortBanditLoopActive || !_stage53Active || !_escortActor
			Return
		EndIf

		_SpawnEscortBandit()
	EndWhile
EndFunction

Function _SpawnEscortBandit()
	If EscortBanditBase == None || _escortActor == None
		Return
	EndIf

	ObjectReference src = _escortActor
	Actor bandit = src.PlaceAtMe(EscortBanditBase, 1) as Actor
	If !bandit
		Return
	EndIf

	; небольшое случайное смещение
	Float dx = Utility.RandomFloat(-400.0, 400.0)
	Float dy = Utility.RandomFloat(-400.0, 400.0)
	bandit.MoveTo(_escortActor, dx, dy, 0.0)

	; агрим на животное
	bandit.StartCombat(_escortActor)

	If _escortBanditCount < 128
		_escortBandits[_escortBanditCount] = bandit
		_escortBanditCount += 1
	EndIf

	_Notify("Бандит напал на существо!")
EndFunction

Function _UpdateStage53()
	Actor p = Game.GetPlayer()
	If !_stage53Active || !_escortActor || !p
		_stage53FailReason = 2
		_FailStage53()
		Return
	EndIf

	If _escortActor.IsDead()
		_stage53FailReason = 1
		_FailStage53()
		Return
	EndIf

	Float now = Utility.GetCurrentRealTime()
	Float dist = _escortActor.GetDistance(p)

	If dist > 3000.0
		If _escortIgnoreSince <= 0.0
			_escortIgnoreSince = now
		ElseIf (now - _escortIgnoreSince) >= 20.0
			_stage53FailReason = 2
			_FailStage53()
			Return
		EndIf
	Else
		_escortIgnoreSince = 0.0
	EndIf

	If now >= _escortEndTime
		_SuccessStage53()
		Return
	EndIf

	RegisterForSingleUpdate(1.0)
EndFunction

Function _SuccessStage53()
	Int idx = Utility.RandomInt(0, EscortRewardChests.GetSize() - 1)
	Container chestBase = EscortRewardChests.GetAt(idx) as Container

	If chestBase
		_escortChest = _escortActor.PlaceAtMe(chestBase, 1)
		If _escortChest
			_escortChest.MoveTo(_escortActor)
			_Notify("Существо благополучно пережило путь. Награда ожидает вас.")
			_RemoveEscortChestDelayed()
		EndIf
	EndIf

	_CleanupStage53_Internal()
EndFunction

Function _RemoveEscortChestDelayed()
	ObjectReference chest = _escortChest
	Utility.Wait(30.0)

	If chest
		chest.Disable()
		chest.Delete()
	EndIf

	If chest == _escortChest
		_escortChest = None
	EndIf
EndFunction

Function _FailStage53()
	If _stage53FailReason == 1
		_Notify("Существо погибло.")
	ElseIf _stage53FailReason == 2
		_Notify("Вы ушли слишком далеко от существа.")
	EndIf

	_CleanupStage53_Internal()
	_pendingWrath = true
	RegisterForSingleUpdate(0.1)
EndFunction

Function _CleanupStage53_Internal()
	SetObjectiveDisplayed(530, false)

	If EscortTargetAlias
		EscortTargetAlias.Clear()
	EndIf

	If _escortActor
		_escortActor.Disable()
		_escortActor.Delete()
	EndIf

	_escortBanditLoopActive = false

	If _escortBandits
		Int i = 0
		While i < _escortBanditCount
			Actor a = _escortBandits[i]
			If a
				a.Disable()
				a.Delete()
			EndIf
			i += 1
		EndWhile
	EndIf

	_escortBanditCount = 0

	_escortActor = None
	_stage53Active = false
	_escortIgnoreSince = 0.0
	_escortEndTime = 0.0
	_stage53FailReason = 0
EndFunction

; =====================================================
; UPDATE LOOP
; =====================================================
Event OnUpdate()
	If _stage50Active
		If Utility.GetCurrentRealTime() >= _stage50EndTime
			_EndStage50()
		Else
			_UpdateStage50()
		EndIf
	EndIf

	If _stage51Active
		_UpdateStage51()
	EndIf

	If _stage52Active
		_UpdateStage52()
	EndIf

	If _stage53Active
		_UpdateStage53()
	EndIf

	If _arenaCleanupPending && Utility.GetCurrentRealTime() >= _arenaCorpseCleanupAt
		_CleanupArenaCorpses()
	EndIf

	If _pendingWrath
		_pendingWrath = false
		If MainControllerQuest
			MainControllerQuest.SetStage(11)
		EndIf
	EndIf

	If _stage50Active || _stage51Active || _stage52Active || _stage53Active || _arenaCleanupPending
		RegisterForSingleUpdate(0.5)
	EndIf
EndEvent