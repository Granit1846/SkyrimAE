ScriptName TDL_Creatures extends Quest

; === СВОЙСТВА ДЛЯ CK ===
Actor Property PlayerRef Auto
Spell Property TDL_SummonFX Auto
Sound Property TDL_SummonSound Auto

FormList Property TDL_CreatureList_Animal Auto
FormList Property TDL_CreatureList_Danger Auto
FormList Property TDL_CreatureList_Dragon Auto
FormList Property TDL_CreatureList_Humanoid Auto
FormList Property TDL_CreatureList_Skeleton Auto
FormList Property TDL_CreatureList_Strong Auto
FormList Property TDL_CreatureList_Undead_and_Other Auto

GlobalVariable Property TDL_CreatureCategoryGV Auto

; === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
Actor SummonedCreature
Int CurrentCategory = -1
Bool IsProcessing = false

; ================= ИНИЦИАЛИЗАЦИЯ =================
Event OnInit()
    Debug.Notification("[TDL] Система существ инициализирована")
    Debug.Trace("[TDL] Creatures: OnInit()")
    
    ; Запускаем квест если он не запущен
    If !IsRunning()
        Start()
        Debug.Trace("[TDL] Creatures: Квест запущен автоматически")
    EndIf
    
    ; Получаем ссылку на игрока
    PlayerRef = Game.GetPlayer()
    
    ; Устанавливаем начальные стадии
    SetStage(0)  ; Квест активен
    SetStage(100) ; Готов к командам
EndEvent

; ================= ОСНОВНОЙ ОБРАБОТЧИК =================
Event OnStageSet(Int aiStage, Int aiItemID)
    Debug.Notification("[TDL] Стадия: " + aiStage)
    Debug.Trace("[TDL] Creatures: OnStageSet(" + aiStage + ")")
    
    ; Запускаем обработку команды
    ProcessStage(aiStage)
    
    ; Сбрасываем стадию для возможности повторного вызова
    If aiStage >= 10 && aiStage <= 27
        SetStage(100)
    EndIf
EndEvent

; ================= ОБРАБОТКА КОМАНД =================
Function ProcessStage(Int stage)
    If IsProcessing
        Debug.Notification("[TDL] Подождите, идет обработка...")
        Return
    EndIf
    
    IsProcessing = true
    
    ; Задержка для стабильности
    Utility.Wait(0.2)
    
    ; Обрабатываем команды
    If stage == 10
        Debug.Notification("[TDL] Команда: случайное существо")
        SummonRandomCreatureFromAll()
    ElseIf stage == 20
        Debug.Notification("[TDL] Команда: существо из выбранной категории")
        SummonFromGlobalCategory()
    ElseIf stage == 21
        Debug.Notification("[TDL] Команда: Животные (Категория 0)")
        SummonFromCategory(0)
    ElseIf stage == 22
        Debug.Notification("[TDL] Команда: Опасные существа (Категория 1)")
        SummonFromCategory(1)
    ElseIf stage == 23
        Debug.Notification("[TDL] Команда: Драконы (Категория 2)")
        SummonFromCategory(2)
    ElseIf stage == 24
        Debug.Notification("[TDL] Команда: Гуманоиды (Категория 3)")
        SummonFromCategory(3)
    ElseIf stage == 25
        Debug.Notification("[TDL] Команда: Скелеты (Категория 4)")
        SummonFromCategory(4)
    ElseIf stage == 26
        Debug.Notification("[TDL] Команда: Сильные противники (Категория 5)")
        SummonFromCategory(5)
    ElseIf stage == 27
        Debug.Notification("[TDL] Команда: Нежить/Другое (Категория 6)")
        SummonFromCategory(6)
    Else
        Debug.Notification("[TDL] Неизвестная команда: " + stage)
    EndIf
    
    ; Снимаем флаг обработки
    IsProcessing = false
EndFunction

; ================= ПРИЗЫВ ИЗ ГЛОБАЛЬНОЙ ПЕРЕМЕННОЙ =================
Function SummonFromGlobalCategory()
    If TDL_CreatureCategoryGV == None
        Debug.Notification("[TDL] Ошибка: Глобальная переменная не назначена!")
        Return
    EndIf
    
    Int category = TDL_CreatureCategoryGV.GetValueInt()
    Debug.Notification("[TDL] Категория из глобалки: " + category)
    
    ; Проверяем диапазон
    If category < 0
        category = 0
    ElseIf category > 6
        category = 6
    EndIf
    
    CurrentCategory = category
    SummonFromCategory(category)
EndFunction

; ================= ПРИЗЫВ СУЩЕСТВА =================
Function SummonCreature(Form creatureForm, String categoryName)
    If creatureForm == None
        Debug.Notification("[TDL] Ошибка: Форма существа не найдена")
        Return
    EndIf
    
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
        If PlayerRef == None
            Debug.Notification("[TDL] Ошибка: Игрок не найден")
            Return
        EndIf
    EndIf
    
    ; Очищаем предыдущее существо
    CleanupSummonedCreature()
    UnregisterForUpdate()
    
    ; Звуковой эффект
    If TDL_SummonSound != None
        TDL_SummonSound.Play(PlayerRef)
    EndIf
    
    ; Создаем существо
    Actor creature = PlayerRef.PlaceAtMe(creatureForm) as Actor
    If creature == None
        Debug.Notification("[TDL] Ошибка создания существа")
        Return
    EndIf
    
    ; Позиционируем перед игроком
    Float angleZ = PlayerRef.GetAngleZ()
    Float distance = 300.0
    Float offsetX = distance * Math.Sin(angleZ)
    Float offsetY = distance * Math.Cos(angleZ)
    
    creature.MoveTo(PlayerRef, offsetX, offsetY, 0.0)
    
    ; Делаем враждебным
    creature.StartCombat(PlayerRef)
    Debug.Notification("[TDL] Призвано: " + categoryName)
    
    ; Визуальный эффект
    If TDL_SummonFX != None
        TDL_SummonFX.Cast(PlayerRef, creature)
    EndIf
    
    ; Сохраняем ссылку для удаления
    SummonedCreature = creature
    
    ; Устанавливаем таймер удаления (2 минуты)
    RegisterForSingleUpdate(120.0)
    Debug.Trace("[TDL] Существо создано: " + categoryName)
EndFunction

; ================= УДАЛЕНИЕ СУЩЕСТВА =================
Event OnUpdate()
    CleanupSummonedCreature()
EndEvent

Function CleanupSummonedCreature()
    If SummonedCreature != None
        Debug.Notification("[TDL] Существо исчезает...")
        SummonedCreature.Disable(true)
        SummonedCreature.Delete()
        SummonedCreature = None
        Debug.Trace("[TDL] Существо удалено")
    EndIf
EndFunction

; ================= ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =================
FormList Function GetCategoryList(Int categoryIndex)
    If categoryIndex == 0
        Return TDL_CreatureList_Animal
    ElseIf categoryIndex == 1
        Return TDL_CreatureList_Danger
    ElseIf categoryIndex == 2
        Return TDL_CreatureList_Dragon
    ElseIf categoryIndex == 3
        Return TDL_CreatureList_Humanoid
    ElseIf categoryIndex == 4
        Return TDL_CreatureList_Skeleton
    ElseIf categoryIndex == 5
        Return TDL_CreatureList_Strong
    ElseIf categoryIndex == 6
        Return TDL_CreatureList_Undead_and_Other
    EndIf
    
    Debug.Trace("[TDL] Ошибка: неверный индекс категории: " + categoryIndex)
    Return None
EndFunction

String Function GetCategoryName(Int categoryIndex)
    If categoryIndex == 0
        Return "Животное"
    ElseIf categoryIndex == 1
        Return "Опасное существо"
    ElseIf categoryIndex == 2
        Return "Дракон"
    ElseIf categoryIndex == 3
        Return "Гуманоид"
    ElseIf categoryIndex == 4
        Return "Скелет"
    ElseIf categoryIndex == 5
        Return "Сильный противник"
    ElseIf categoryIndex == 6
        Return "Нежить/другое"
    EndIf
    
    Return "Неизвестное существо"
EndFunction

; ================= СЛУЧАЙНЫЙ ПРИЗЫВ =================
Function SummonRandomCreatureFromAll()
    Debug.Notification("[TDL] Призываю случайное существо...")
    
    ; Пробуем несколько раз найти непустую категорию
    Int attempts = 0
    While attempts < 20
        Int randomCategory = Utility.RandomInt(0, 6)
        FormList categoryList = GetCategoryList(randomCategory)
        
        If categoryList != None
            Int listSize = categoryList.GetSize()
            If listSize > 0
                Int randomIndex = Utility.RandomInt(0, listSize - 1)
                Form creatureForm = categoryList.GetAt(randomIndex)
                String categoryName = GetCategoryName(randomCategory)
                
                SummonCreature(creatureForm, categoryName)
                Return
            EndIf
        EndIf
        
        attempts += 1
    EndWhile
    
    Debug.Notification("[TDL] Ошибка: все списки пусты!")
EndFunction

; ================= ПРИЗЫВ ИЗ КОНКРЕТНОЙ КАТЕГОРИИ =================
Function SummonFromCategory(Int categoryIndex)
    Debug.Notification("[TDL] Призываю из категории " + categoryIndex)
    
    ; Проверяем диапазон
    If categoryIndex < 0 || categoryIndex > 6
        Debug.Notification("[TDL] Ошибка: неверная категория " + categoryIndex)
        Return
    EndIf
    
    ; Получаем список категории
    FormList categoryList = GetCategoryList(categoryIndex)
    If categoryList == None
        Debug.Notification("[TDL] Ошибка: список категории не найден")
        Return
    EndIf
    
    ; Проверяем, есть ли существа в списке
    Int listSize = categoryList.GetSize()
    If listSize <= 0
        Debug.Notification("[TDL] Ошибка: список категории пуст")
        Return
    EndIf
    
    ; Выбираем случайное существо из списка
    Int randomIndex = Utility.RandomInt(0, listSize - 1)
    Form creatureForm = categoryList.GetAt(randomIndex)
    
    If creatureForm == None
        Debug.Notification("[TDL] Ошибка: форма существа не загружена")
        Return
    EndIf
    
    ; Получаем имя категории и призываем
    String categoryName = GetCategoryName(categoryIndex)
    SummonCreature(creatureForm, categoryName)
EndFunction

; ================= ФУНКЦИИ ДЛЯ КОНСОЛИ =================
Function ConsoleSummonCategory(Int categoryIndex)
    Debug.Notification("[TDL] Консольная команда: категория " + categoryIndex)
    SummonFromCategory(categoryIndex)
EndFunction

Function ConsoleSetCategory(Int categoryIndex)
    If TDL_CreatureCategoryGV != None
        TDL_CreatureCategoryGV.SetValueInt(categoryIndex)
        Debug.Notification("[TDL] Установлена категория: " + categoryIndex)
    Else
        Debug.Notification("[TDL] Ошибка: глобальная переменная не назначена")
    EndIf
EndFunction

Function ConsoleTest()
    Debug.Notification("[TDL] Тест системы существ...")
    
    ; Проверяем списки
    Int emptyLists = 0
    Int i = 0
    While i < 7
        FormList fl = GetCategoryList(i)
        If fl == None
            Debug.Notification("[TDL] Список " + i + ": не назначен")
            emptyLists += 1
        ElseIf fl.GetSize() <= 0
            Debug.Notification("[TDL] Список " + i + ": пуст")
            emptyLists += 1
        Else
            Debug.Notification("[TDL] Список " + i + ": OK (" + fl.GetSize() + " существ)")
        EndIf
        i += 1
    EndWhile
    
    If emptyLists == 7
        Debug.Notification("[TDL] ВНИМАНИЕ: Все списки пусты!")
    EndIf
EndFunction