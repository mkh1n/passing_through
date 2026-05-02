extends Node
## EventManager - Управление событиями и сценариями (Autoload)
## Загружает события из JSON, фильтрует по контексту, управляет эхо-системой

signal event_loaded(event_data: Dictionary)
signal choices_presented(choices: Array[Dictionary])
signal event_completed(result: Dictionary)
signal minigame_requested(minigame_type: String, difficulty: float)
signal minigame_result(success: bool)

var events_db: Array[Dictionary] = []
var archetypes_db: Dictionary = {}
var current_event: Dictionary = {}
var available_events: Array[Dictionary] = []


func _ready() -> void:
	load_events_database()
	load_archetypes_database()


## Загрузка базы событий из JSON
func load_events_database() -> void:
	var dir := DirAccess.open("res://data/events")
	if not dir:
		print("Ошибка: папка data/events не найдена")
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var path := "res://data/events/" + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json_string := file.get_as_text()
				var json := JSON.new()
				var error := json.parse(json_string)
				if error == OK:
					var data: Variant = json.data
					if data is Array:
						events_db.append_array(data)
					elif data is Dictionary:
						events_db.append(data)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Загружено событий: ", events_db.size())


## Загрузка базы архетипов из JSON
func load_archetypes_database() -> void:
	var dir := DirAccess.open("res://data/archetypes")
	if not dir:
		print("Предупреждение: папка data/archetypes не найдена")
		archetypes_db = create_default_archetypes()
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var path := "res://data/archetypes/" + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json_string := file.get_as_text()
				var json := JSON.new()
				var error := json.parse(json_string)
				if error == OK:
					var data: Variant = json.data
					if data is Dictionary:
						archetypes_db.merge(data, true)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if archetypes_db.is_empty():
		archetypes_db = create_default_archetypes()


## Создание архетипов по умолчанию (если JSON не загружены)
func create_default_archetypes() -> Dictionary:
	return {
		"euphoric": {
			"name": "Эйфорик",
			"description": "Видит мир в розовом свете",
			"text_modifier": "bright",
			"color_tint": Color(1, 0.8, 0.6, 0.3)
		},
		"obsessive": {
			"name": "Одержимый",
			"description": "Фокусируется на деталях",
			"text_modifier": "detailed",
			"color_tint": Color(0.7, 0.5, 0.9, 0.3)
		},
		"cynic": {
			"name": "Циник",
			"description": "Смотрит на мир с иронией",
			"text_modifier": "ironic",
			"color_tint": Color(0.5, 0.5, 0.5, 0.3)
		},
		"fleeing": {
			"name": "Беглец",
			"description": "Избегает прямого контакта",
			"text_modifier": "distant",
			"color_tint": Color(0.6, 0.7, 0.9, 0.3)
		},
		"healer": {
			"name": "Целитель",
			"description": "Ищет возможности помочь",
			"text_modifier": "caring",
			"color_tint": Color(0.6, 0.9, 0.6, 0.3)
		},
		"nihilist": {
			"name": "Нигилист",
			"description": "Не видит смысла в происходящем",
			"text_modifier": "empty",
			"color_tint": Color(0.3, 0.3, 0.3, 0.3)
		},
		"selfharm": {
			"name": "Самоповреждающий",
			"description": "Склонен к саморазрушению",
			"text_modifier": "dark",
			"color_tint": Color(0.8, 0.3, 0.4, 0.3)
		}
	}


## Получение доступных событий для текущего контекста
func get_available_events(context: Dictionary) -> Array[Dictionary]:
	available_events.clear()
	
	for event in events_db:
		if is_event_available(event, context):
			available_events.append(event)
	
	# Приоритет эхо-событиям
	if GameState.echo_events.size() > 0:
		for event in available_events:
			if event.get("id", "") in GameState.echo_events:
				available_events.erase(event)
				available_events.insert(0, event)
				break
	
	return available_events


## Проверка доступности события
func is_event_available(event: Dictionary, context: Dictionary) -> bool:
	var event_id: String = event.get("id", "")
	
	# Проверка дня
	var day_min: int = event.get("day_min", 1)
	var day_max: int = event.get("day_max", 15)
	if GameState.current_day < day_min or GameState.current_day > day_max:
		return false
	
	# Проверка состояния
	var state_req: Variant = event.get("state_requirement", null)
	if state_req != null:
		var min_state: int = state_req.get("min", -2) if state_req is Dictionary else -2
		var max_state: int = state_req.get("max", 2) if state_req is Dictionary else 2
		if GameState.state < min_state or GameState.state > max_state:
			return false
	
	# Проверка треков
	var track_req: Variant = event.get("track_requirement", null)
	if track_req != null and track_req is Dictionary:
		var track_type: String = track_req.get("type", "")
		var track_value: int = 0
		match track_type:
			"action": track_value = GameState.action_track
			"observe": track_value = GameState.observe_track
			"connect": track_value = GameState.connect_track
		
		var min_required: int = track_req.get("min", 0)
		if track_value < min_required:
			return false
	
	# Проверка на уже пройденное (если не эхо)
	if not event.get("repeatable", false):
		if event_id in GameState.echo_events:
			pass # Эхо можно повторять
		else:
			# Можно добавить проверку на уже пройденные
			pass
	
	return true


## Начало события
func start_event(event: Dictionary) -> void:
	current_event = event
	GameState.current_event = event
	event_loaded.emit(event)
	
	# Представление выборов
	present_choices(event)


## Представление выборов игроку
func present_choices(event: Dictionary) -> void:
	var choices: Array[Dictionary] = event.get("choices", [])
	
	# Модификация текстов выборов в зависимости от архетипа
	var dominant_archetype: String = GameState.get_dominant_archetype()
	var archetype_data: Dictionary = archetypes_db.get(dominant_archetype, {})
	
	for choice in choices:
		var text_modifier: String = archetype_data.get("text_modifier", "")
		if text_modifier != "" and choice.has("text_variants"):
			choice["text"] = choice["text_variants"].get(text_modifier, choice.get("text", ""))
	
	choices_presented.emit(choices)


## Обработка выбора игрока
func make_choice(choice_index: int) -> void:
	if current_event.is_empty():
		return
	
	var choices: Array[Dictionary] = current_event.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return
	
	var choice: Dictionary = choices[choice_index]
	
	# Мини-игра, если требуется (сначала мини-игра, потом результат)
	if choice.get("minigame", null):
		var minigame_type: String = choice.minigame.get("type", "focus")
		var difficulty: float = calculate_minigame_difficulty(choice.minigame)
		minigame_requested.emit(minigame_type, difficulty)
		# Результат будет обработан после завершения мини-игры
	else:
		var result: Dictionary = process_choice_outcome(choice)
		event_completed.emit(result)
		
		# Добавление в эхо, если событие пропущено
		if choice.get("skip_event", false):
			GameState.add_echo(current_event.get("id", ""))


## Расчёт сложности мини-игры
func calculate_minigame_difficulty(minigame_data: Dictionary) -> float:
	var base_difficulty: float = minigame_data.get("base_difficulty", 0.5)
	
	# Корректировка по состоянию
	var state_factor: float = float(GameState.state + 2) / 4.0 # 0.0 to 1.0
	base_difficulty -= state_factor * 0.3 # Уменьшаем сложность при хорошем состоянии
	
	return clamp(base_difficulty, 0.2, 0.9)


## Обработка последствий выбора
func process_choice_outcome(choice: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"success": true,
		"state_change": choice.get("state_change", 0),
		"track_changes": choice.get("track_changes", {}),
		"archetype_shifts": choice.get("archetype_shifts", {}),
		"photo_options": choice.get("photo_options", []),
		"echo_trigger": choice.get("echo_trigger", null)
	}
	
	# Применение изменений состояния
	if result.state_change != 0:
		GameState.update_state(result.state_change)
	
	# Применение изменений треков
	for track_type in result.track_changes.keys():
		GameState.add_to_track(track_type, result.track_changes[track_type])
	
	# Применение сдвигов архетипов
	for archetype in result.archetype_shifts.keys():
		GameState.shift_archetype(archetype, result.archetype_shifts[archetype])
	
	# Добавление фото опций
	if result.photo_options.size() > 0:
		for photo in result.photo_options:
			GameState.add_daily_photo(photo)
	
	# Триггер эхо
	if result.echo_trigger:
		GameState.add_echo(result.echo_trigger)
	
	return result


## Обработка результата мини-игры
func handle_minigame_result(success: bool) -> void:
	minigame_result.emit(success)
	
	if current_event.is_empty():
		return
	
	# Поиск выбора с мини-игрой
	for choice in current_event.get("choices", []):
		if choice.has("minigame"):
			var outcome_key: String = "success_outcome" if success else "fail_outcome"
			var outcome: Dictionary = choice.minigame.get(outcome_key, {})
			process_choice_outcome(outcome)
			break
