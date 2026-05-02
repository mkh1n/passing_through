extends Node
## GameManager - Управление игровым циклом (Autoload)
## Инициализация игры, запуск дней, управление фазами игры

signal day_phase_changed(phase: String)
signal game_started()
signal game_ended()

enum GamePhase {
	MORNING,	# Утро - выбор направления
	PATH,		# Путь - движение к событию
	SCENE,		# Сцена - событие
	PHOTO,		# Фото - выбор кадра
	EVENING,	# Вечер - сохранение памяти
	NIGHT		# Ночь - рефлексия/эхо
}

var current_phase: GamePhase = GamePhase.MORNING
var is_game_running: bool = false
var events_today: int = 0
var max_events_per_day: int = 3


func _ready() -> void:
	print("GameManager готов")


## Запуск новой игры
func start_new_game() -> void:
	GameState.start_new_game()
	MemorySystem.reset_memory()
	is_game_running = true
	events_today = 0
	current_phase = GamePhase.MORNING
	
	game_started.emit()
	change_phase(GamePhase.MORNING)


## Смена фазы дня
func change_phase(new_phase: GamePhase) -> void:
	current_phase = new_phase
	
	var phase_names: Dictionary = {
		GamePhase.MORNING: "morning",
		GamePhase.PATH: "path",
		GamePhase.SCENE: "scene",
		GamePhase.PHOTO: "photo",
		GamePhase.EVENING: "evening",
		GamePhase.NIGHT: "night"
	}
	
	day_phase_changed.emit(phase_names[new_phase])
	
	match new_phase:
		GamePhase.MORNING:
			_on_morning_phase()
		GamePhase.PATH:
			_on_path_phase()
		GamePhase.SCENE:
			_on_scene_phase()
		GamePhase.PHOTO:
			_on_photo_phase()
		GamePhase.EVENING:
			_on_evening_phase()
		GamePhase.NIGHT:
			_on_night_phase()


## Утренняя фаза - начало дня
func _on_morning_phase() -> void:
	print("🌅 УТРО - День ", GameState.current_day)
	# Здесь можно добавить выбор направления/линзы
	# Пока просто переходим к пути
	await get_tree().create_timer(2.0).timeout
	change_phase(GamePhase.PATH)


## Фаза пути - движение к событию
func _on_path_phase() -> void:
	print("🚶 ПУТЬ - Движение...")
	# Параллакс движение, музыка
	# Поиск и запуск события
	await get_tree().create_timer(1.5).timeout
	start_event_sequence()


## Запуск последовательности событий
func start_event_sequence() -> void:
	if events_today >= max_events_per_day:
		change_phase(GamePhase.EVENING)
		return
	
	# Получение доступного события
	var context: Dictionary = {
		"day": GameState.current_day,
		"state": GameState.state,
		"lens": GameState.current_lens
	}
	
	var available: Array[Dictionary] = EventManager.get_available_events(context)
	
	if available.is_empty():
		print("Нет доступных событий для текущего контекста")
		change_phase(GamePhase.EVENING)
		return
	
	# Выбор случайного события (можно улучшить логику выбора)
	var event_index: int = randi() % available.size()
	var selected_event: Dictionary = available[event_index]
	
	print("🎭 СЦЕНА - ", selected_event.get("title", "Неизвестно"))
	EventManager.start_event(selected_event)
	change_phase(GamePhase.SCENE)


## Фаза сцены - событие активно
func _on_scene_phase() -> void:
	print("Сцена активна, ожидание выбора игрока...")
	# UI отобразит событие и выборы
	# Ждём завершения события через сигнал


## Фаза фото - выбор кадра
func _on_photo_phase() -> void:
	print("📸 ФОТО - Выбор кадра восприятия")
	# UI покажет варианты фото
	# Игрок выбирает один кадр


## Вечерняя фаза - завершение дня
func _on_evening_phase() -> void:
	print("🌙 ВЕЧЕР - Завершение дня")
	# Игрок сохраняет 1 фото из дневных
	# Остальные исчезают
	
	# Если фото ещё не выбрано, даём время на выбор
	if GameState.daily_photos.size() > 0:
		print("Ожидание выбора финального фото...")
	else:
		# Автоматический переход если нет фото
		await get_tree().create_timer(2.0).timeout
		change_phase(GamePhase.NIGHT)


## Ночная фаза - рефлексия
func _on_night_phase() -> void:
	print("🌫 НОЧЬ - Рефлексия")
	# Короткий текст
	# Возможное эхо прошлых событий
	
	await get_tree().create_timer(3.0).timeout
	
	# Переход к следующему дню
	if GameState.current_day < 15:
		GameState.start_next_day()
		events_today = 0
		change_phase(GamePhase.MORNING)
	else:
		end_game()


## Завершение игры (после 15 дней)
func end_game() -> void:
	is_game_running = false
	game_ended.emit()
	change_phase(GamePhase.NIGHT)
	
	# Показ финала
	show_final_interpretation()


## Показ финальной интерпретации
func show_final_interpretation() -> void:
	print("📊 ФИНАЛ - Сборка опыта")
	
	var analysis: Dictionary = MemorySystem.analyze_memory()
	var dominant_archetype: String = GameState.get_dominant_archetype()
	var archetype_data: Dictionary = EventManager.archetypes_db.get(dominant_archetype, {})
	
	print("Доминирующий архетип: ", dominant_archetype)
	print("Интерпретация: ", archetype_data.get("final_interpretation", "Нет данных"))
	print("Статистика восприятия: ", analysis.perception_distribution)
	print("Всего дней: ", analysis.total_days)


## Обработка завершения события
func on_event_completed(result: Dictionary) -> void:
	events_today += 1
	
	# Переход к фазе фото если есть опции
	if result.photo_options and result.photo_options.size() > 0:
		change_phase(GamePhase.PHOTO)
	else:
		# Если нет фото, сразу проверяем завершение дня
		if events_today >= max_events_per_day:
			change_phase(GamePhase.EVENING)
		else:
			change_phase(GamePhase.PATH)


## Обработка выбора фото
func on_photo_selected(index: int) -> void:
	# Фото выбрано и сохранено в MemorySystem
	change_phase(GamePhase.EVENING)
