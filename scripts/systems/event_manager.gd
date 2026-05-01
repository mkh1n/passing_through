## EventManager - Управление событиями и нарративом
## Загружает события из JSON, фильтрует их по контексту, управляет эхо-событиями
## Все события хранятся в папке data/events/

extends Node

# ==================== СИГНАЛЫ ====================
signal event_started(event_data: Dictionary)
signal event_completed(event_id: String, choice_index: int)
signal event_failed(event_id: String, reason: String)

# ==================== ПЕРЕМЕННЫЕ ====================
# Все загруженные события
var all_events: Array = []

# Текущее активное событие
var current_event: Dictionary = {}

# ID событий, которые уже произошли
var completed_events: Array = []

# События с риском, которые проигнорировал игрок (для эхо)
var ignored_risky_events: Array = []

# Путь к папке с событиями (настроить под проект)
@export var events_folder: String = "res://data/events/"

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	print("[EventManager] Initialized")
	load_all_events()

# ==================== ЗАГРУЗКА СОБЫТИЙ ====================
## Загружает все события из JSON файлов
func load_all_events() -> void:
	all_events.clear()
	
	var dir := DirAccess.open(events_folder)
	if not dir:
		push_error("[EventManager] Cannot access events folder: %s" % events_folder)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var file_path := events_folder + file_name
			var events := load_events_from_json(file_path)
			all_events.append_array(events)
			print("[EventManager] Loaded %d events from %s" % [events.size(), file_name])
		
		file_name = dir.get_next()
	
	print("[EventManager] Total events loaded: %d" % all_events.size())

## Парсит JSON файл с событиями
func load_events_from_json(file_path: String) -> Array:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[EventManager] Cannot open file: %s" % file_path)
		return []
	
	var json_string := file.get_as_text()
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	
	if parse_result != OK:
		push_error("[EventManager] JSON parse error in %s: %s" % [file_path, json.get_error_message()])
		return []
	
	var data = json.data
	if data is Array:
		return data
	elif data is Dictionary and data.has("events"):
		return data["events"]
	else:
		push_error("[EventManager] Invalid JSON structure in %s" % file_path)
		return []

# ==================== ПОЛУЧЕНИЕ СОБЫТИЙ ====================
## Получает следующее доступное событие с учётом контекста
func get_next_event(context: Dictionary = {}) -> Dictionary:
	var available_events := filter_events(context)
	
	if available_events.is_empty():
		return create_fallback_event()
	
	# Выбираем случайное событие из доступных
	var selected := available_events[randi() % available_events.size()]
	return selected

## Фильтрует события по условиям
func filter_events(context: Dictionary) -> Array:
	var filtered := []
	
	for event in all_events:
		if not is_event_available(event, context):
			continue
		
		if is_event_completed(event):
			continue
		
		filtered.append(event)
	
	return filtered

## Проверяет, доступно ли событие для запуска
func is_event_available(event: Dictionary, context: Dictionary) -> bool:
	# Проверка дня
	if event.has("min_day") and GameState.current_day < event["min_day"]:
		return false
	
	if event.has("max_day") and GameState.current_day > event["max_day"]:
		return false
	
	# Проверка состояния
	if event.has("min_state") and GameState.player_state < event["min_state"]:
		return false
	
	if event.has("max_state") and GameState.player_state > event["max_state"]:
		return false
	
	# Проверка треков
	if event.has("required_tracks"):
		for track in event["required_tracks"]:
			if GameState.tracks.get(track, 0) < event["required_tracks"][track]:
				return false
	
	# Проверка предыдущих выборов
	if event.has("requires_previous_choice"):
		var req := event["requires_previous_choice"]
		if not completed_events.has(req["event_id"]):
			return false
		# Можно добавить проверку конкретного выбора
	
	# Проверка локации
	if event.has("location") and context.get("location") != event["location"]:
		return false
	
	return true

## Проверяет, завершено ли событие
func is_event_completed(event: Dictionary) -> bool:
	return completed_events.has(event.get("id", ""))

## Создаёт резервное событие, если ничего не подошло
func create_fallback_event() -> Dictionary:
	return {
		"id": "fallback_%d" % randi(),
		"title": "Обычный момент",
		"description": "Ничего особенного не происходит. Ты просто идёшь дальше.",
		"choices": [
			{"text": "Продолжить путь", "next_scene": "travel", "track": "observe"}
		],
		"type": "narrative",
		"archetype_shift": {}
	}

# ==================== УПРАВЛЕНИЕ СОБЫТИЯМИ ====================
## Запускает событие
func start_event(event: Dictionary) -> void:
	current_event = event
	event_started.emit(event)
	print("[EventManager] Started event: %s" % event.get("title", "unknown"))

## Завершает событие с выбором
func complete_event(choice_index: int) -> void:
	if current_event.is_empty():
		return
	
	var event_id := current_event.get("id", "")
	completed_events.append(event_id)
	
	# Применяем эффекты выбора
	apply_choice_effects(choice_index)
	
	event_completed.emit(event_id, choice_index)
	current_event = {}
	print("[EventManager] Completed event: %s with choice %d" % [event_id, choice_index])

## Пропускает событие (для эхо-системы)
func skip_event() -> void:
	if current_event.is_empty():
		return
	
	var event_id := current_event.get("id", "")
	
	# Если событие с риском, добавляем в эхо
	if current_event.get("risk", false):
		ignored_risky_events.append(current_event.duplicate(true))
		GameState.add_echo_event(event_id, current_event)
	
	current_event = {}

## Применяет эффекты выбора
func apply_choice_effects(choice_index: int) -> void:
	if not current_event.has("choices") or choice_index >= current_event["choices"].size():
		return
	
	var choice := current_event["choices"][choice_index]
	
	# Изменение треков
	if choice.has("track"):
		GameState.add_track(choice["track"], choice.get("track_amount", 1))
	
	# Изменение состояния
	if choice.has("state_change"):
		GameState.change_state(choice["state_change"])
	
	# Сдвиг архетипа
	if choice.has("archetype_shift"):
		for archetype in choice["archetype_shift"]:
			GameState.shift_archetype(archetype, choice["archetype_shift"][archetype])
	
	# Мини-игра
	if choice.has("minigame"):
		# Будет обработано MinigameManager
		pass

# ==================== ЭХО-СИСТЕМА ====================
## Проверяет и возвращает эхо-события
func check_and_get_echo_event() -> Dictionary:
	var active_echos := GameState.check_echo_events()
	
	if active_echos.is_empty() or ignored_risky_events.is_empty():
		return {}
	
	# Находим эхо для пропущенного рискованного события
	for echo in active_echos:
		for ignored in ignored_risky_events:
			if ignored.get("id") == echo["id"]:
				# Возвращаем модифицированную версию события
				var echo_event := ignored.duplicate(true)
				echo_event["is_echo"] = true
				echo_event["title"] = "Эхо: " + echo_event["title"]
				echo_event["description"] = get_echo_description(echo_event)
				return echo_event
	
	return {}

## Генерирует описание для эхо-события
func get_echo_description(event: Dictionary) -> String:
	var base_desc := event.get("description", "")
	
	# Добавляем последствия
	if event.get("echo_consequence") == "negative":
		return base_desc + "\n\n[Ты чувствуешь, что упустил что-то важное. Теперь всё иначе.]"
	elif event.get("echo_consequence") == "transformed":
		return base_desc + "\n\n[Момент вернулся, но изменился. Как и ты.]"
	else:
		return base_desc + "\n\n[Это снова перед тобой. Второй шанс?]"

# ==================== ИНТЕГРАЦИЯ С АРХЕТИПАМИ ====================
## Модифицирует текст события под текущий архетип
func flavor_event_with_archetype(event: Dictionary) -> Dictionary:
	var flavored := event.duplicate(true)
	var archetype := GameState.get_dominant_archetype()
	
	# Если есть специфичные тексты для архетипа
	if flavored.has("archetype_texts") and flavored["archetype_texts"].has(archetype):
		var arch_text := flavored["archetype_texts"][archetype]
		
		if arch_text.has("title"):
			flavored["title"] = arch_text["title"]
		if arch_text.has("description"):
			flavored["description"] = arch_text["description"]
		if arch_text.has("choices"):
			for i in range(min(arch_text["choices"].size(), flavored["choices"].size())):
				flavored["choices"][i]["text"] = arch_text["choices"][i]
	
	return flavored
