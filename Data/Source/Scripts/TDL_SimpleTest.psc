Scriptname TDL_SimpleTest extends Quest  

Event OnInit()
    Debug.Notification("TDL Simple Test загружен!")
    RegisterForSingleUpdate(1.0)
EndEvent

Event OnUpdate()
    ; Простой тест - попробуйте по одному
    
    ; 1. Тест уведомлений
    Debug.Notification("Тест уведомления: OK")
    
    ; 2. Тест восстановления здоровья
    Actor player = Game.GetPlayer()
    Float healthBefore = player.GetActorValue("Health")
    player.RestoreActorValue("Health", 50)
    Float healthAfter = player.GetActorValue("Health")
    Debug.Notification("Здоровье до: " + healthBefore + ", после: " + healthAfter)
    
    ; 3. Тест тряски камеры
    Game.ShakeCamera(player, 0.5, 1.0)
    Debug.Notification("Тряска камеры: OK")
    
    ; 4. Тест звука (опционально)
    ; Sound testSound = Game.GetForm(0x00033482) as Sound
    ; if testSound
    ;     testSound.Play(player)
    ;     Debug.Notification("Звук: OK")
    ; endif
EndEvent