## GameManager - Главный контроллер игры
## Управляет потоком игры: утро → путь → событие → вечер → ночь
## Координирует все системы между собой

extends Node

# ==================== СИГНАЛЫ ====================
signal game_started
signal day_started(day_number: int)
signal phase_changed(phase: String)
signal game_ended(final_data: Dictionary)

# ==================== КОНСТАНТЫ ====================
enum GamePhase {
	MENU,       # Главное меню
	MORNING,    # Выбор направления
	TRAVEL,     # Путь (параллакс)
	EVENT,      # Событие/сцена
	EVENING,    # Выбор фото
	NIGHT,      # Рефлексия/эхо
	FINAL       # Финал
}

# ==================== ПЕРЕМЕННЫЕ ====================
var current_phase: GamePhase = GamePhase.MENU
var is_game_running: bool = false

# Конфигурация длительности дня (в минутах, для настройки)
var day_duration_minutes: float = 5.0

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	print("[GameManager] Initialized - Ready to start journey")
	# Фаза по умолчанию - меню
	change_phase(GamePhase.MENU)

# ==================== УПРАВЛЕНИЕ ФАЗАМИ ====================
## Меняет текущую фазу игры
func change_phase(new_phase: GamePhase) -> void:
	current_phase = new_phase
	
	var phase_name: = GamePhase.keys()[new_phase]
	phase_changed.emit(phase_name)
	print("[GameManager] Phase changed to: %s" % phase_name)
	
	# Вызываем обработчик фазы
	match new_phase:
		GamePhase.MORNING:
			_on_morning_phase()
		GamePhase.TRAVEL:
			_on_travel_phase()
		GamePhase.EVENT:
			_on_event_phase()
		GamePhase.EVENING:
			_on_evening_phase()
		GamePhase.NIGHT:
			_on_night_phase()
		GamePhase.FINAL:
			_on_final_phase()

# ==================== ЗАПУСК ИГРЫ ====================
## Начинает новую игру
func start_new_game() -> void:
	print("[GameManager] Starting new game")
	
	# Сбрасываем состояние
	reset_game_state()
	
	is_game_running = true
	game_started.emit()
	
	# Начинаем с первого дня
	start_day(1)

## Сбрасывает состояние игры
func reset_game_state() -> void:
	if GameState:
		# Сброс через GameState можно реализовать отдельно
		pass
	
	current_phase = GamePhase.MENU

# ==================== ЦИКЛ ДНЯ ====================
## Запускает новый день
func start_day(day_number: int) -> void:
	GameState.current_day = day_number
	day_started.emit(day_number)
	
	print("[GameManager] Day %d started" % day_number)
	change_phase(GamePhase.MORNING)

## Завершает текущий день
func complete_day() -> void:
	print("[GameManager] Completing day %d" % GameState.current_day)
	
	# Переходим к ночи
	change_phase(GamePhase.NIGHT)

# ==================== ОБРАБОТЧИКИ ФАЗ ====================
## Фаза утра: выбор направления
func _on_morning_phase() -> void:
	print("[GameManager] Morning phase - Player chooses direction")
	# Здесь UI показывает карту/доску с вариантами
	# Игрок выбирает куда пойти

## Фаза путешествия: параллакс-движение
func _on_travel_phase() -> void:
	print("[GameManager] Travel phase - Moving through the city")
	# Запускается сцена с параллаксом
	# Игрок может ускоряться
	# Возможно случайное событие

## Фаза события: нарративный выбор
func _on_event_phase() -> void:
	print("[GameManager] Event phase - Narrative choice")
	# EventManager предоставляет событие
	# Игрок делает выбор
	# Возможно мини-игра

## Фаза вечера: выбор фото
func _on_evening_phase() -> void:
	print("[GameManager] Evening phase - Photo selection")
	# MemorySystem показывает фото за день
	# Игрок выбирает одно для памяти

## Фаза ночи: рефлексия и эхо
func _on_night_phase() -> void:
	print("[GameManager] Night phase - Reflection and echoes")
	# Короткий текст-рефлексия
	# Проверка эхо-событий
	# Подготовка к следующему дню
	
	# Проверяем, не последний ли это день
	if GameState.current_day >= 15:
		change_phase(GamePhase.FINAL)
	else:
		# Авто-переход к утру следующего дня
		await get_tree().create_timer(3.0).timeout
		start_day(GameState.current_day + 1)

## Финальная фаза
func _on_final_phase() -> void:
	print("[GameManager] Final phase - Generating collage")
	is_game_running = false
	
	var final_data: = generate_final_results()
	game_ended.emit(final_data)

# ==================== ФИНАЛЬНЫЕ РЕЗУЛЬТАТЫ ====================
## Генерирует данные для финала
func generate_final_results() -> Dictionary:
	var collage: = {}
	
	if MemorySystem:
		collage = MemorySystem.generate_final_collage()
	
	collage["final_state"] = GameState.player_state
	collage["total_days"] = GameState.current_day - 1
	
	return collage

# ==================== ИНТЕГРАЦИЯ ====================
## Вызывается при выборе направления утром
func on_direction_selected(direction: String) -> void:
	print("[GameManager] Direction selected: %s" % direction)
	
	# Сохраняем выбор
	GameState.add_track("action", 1)
	
	# Переходим к путешествию
	change_phase(GamePhase.TRAVEL)

## Вызывается при завершении путешествия
func on_travel_completed() -> void:
	print("[GameManager] Travel completed")
	
	# Загружаем событие
	change_phase(GamePhase.EVENT)

## Вызывается после выбора в событии
func on_event_completed(event_id: String, choice_index: int) -> void:
	print("[GameManager] Event completed: %s with choice %d" % [event_id, choice_index])
	
	# Переходим к вечеру
	change_phase(GamePhase.EVENING)

## Вызывается после выбора фото
func on_photo_selected(photo_index: int) -> void:
	print("[GameManager] Photo selected: %d" % photo_index)
	
	# Завершаем день
	complete_day()

# ==================== СОХРАНЕНИЕ/ЗАГРУЗКА ====================
## Сохраняет игру
func save_game(slot: int = 0) -> bool:
	var save_data: = {
		"game_state": GameState.save_to_dict(),
		"current_phase": GamePhase.keys()[current_phase],
		"is_running": is_game_running
	}
	
	var file_path: = "user://save_%d.json" % slot
	var file: = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("[GameManager] Cannot save to %s" % file_path)
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	print("[GameManager] Game saved to %s" % file_path)
	return true

## Загружает игру
func load_game(slot: int = 0) -> bool:
	var file_path: = "user://save_%d.json" % slot
	var file: = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		push_error("[GameManager] Cannot load from %s" % file_path)
		return false
	
	var json_string: = file.get_as_text()
	file.close()
	
	var json: = JSON.new()
	var parse_result: = json.parse(json_string)
	
	if parse_result != OK:
		push_error("[GameManager] JSON parse error: %s" % json.get_error_message())
		return false
	
	var save_data = json.data
	
	# Восстанавливаем состояние
	if GameState:
		GameState.load_from_dict(save_data["game_state"])
	
	# Восстанавливаем фазу
	var phase_name: = save_data.get("current_phase", "MENU")
	for i in range(GamePhase.size()):
		if GamePhase.keys()[i] == phase_name:
			current_phase = i
			break
	
	is_game_running = save_data.get("is_running", false)
	
	print("[GameManager] Game loaded from %s" % file_path)
	return true
