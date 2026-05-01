## GameState - Глобальное состояние игры
## Хранит все прогресс-данные: треки, архетипы, состояние, память (фото)
## Это синглтон, доступный из любой точки проекта через GameState

extends Node

# ==================== СИГНАЛЫ ====================
# Сигналы для уведомления других систем об изменениях
signal state_changed(new_value: int)
signal track_changed(track_type: String, new_value: int)
signal archetype_shifted(archetype: String, intensity: float)
signal day_completed(day_number: int)
signal photo_taken(photo_data: Dictionary)
signal memory_updated(memory: Array)

# ==================== КОНСТАНТЫ ====================
# Диапазон состояния игрока (-2 = депрессия, +2 = эйфория)
const STATE_MIN := -2
const STATE_MAX := 2

# Максимальное количество фото за день
const MAX_PHOTOS_PER_DAY := 3

# Типы треков (что игрок делает)
enum TrackType {
	ACTION,      # Активные действия
	OBSERVE,     # Наблюдение
	CONNECT      # Социальные связи
}

# ==================== ПЕРЕМЕННЫЕ СОСТОЯНИЯ ====================
# Текущий день (1-15)
var current_day: int = 1

# Состояние игрока (-2 до +2)
var player_state: int = 0

# Треки развития
var tracks: Dictionary = {
	"action": 0,
	"observe": 0,
	"connect": 0
}

# Архетипы (накопленные очки)
var archetypes: Dictionary = {
	"euphoric": 0,
	"obsessive": 0,
	"cynic": 0,
	"fleeing": 0,
	"healer": 0,
	"nihilist": 0,
	"selfharm": 0
}

# Память - все выбранные фото
var memory: Array = []

# Фото текущего дня (временное хранилище)
var daily_photos: Array = []

# Эхо - пропущенные события, которые вернутся
var echo_events: Array = []

# Текущая линза восприятия
var current_lens: String = "observation"  # participation, observation, connection

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	# Сохраняем этот узел как синглтон
	# В Godot нужно добавить этот скрипт в Project Settings -> Autoload
	print("[GameState] Initialized - Ready to track player journey")

# ==================== УПРАВЛЕНИЕ ДНЁМ ====================
## Начинает новый день
func start_new_day() -> void:
	daily_photos.clear()
	print("[GameState] Day %d started" % current_day)

## Завершает текущий день, сохраняет выбранное фото в память
func complete_day(selected_photo: Dictionary) -> void:
	memory.append(selected_photo)
	day_completed.emit(current_day)
	current_day += 1
	start_new_day()
	print("[GameState] Day completed. Total memories: %d" % memory.size())

# ==================== УПРАВЛЕНИЕ СОСТОЯНИЕМ ====================
## Изменяет состояние игрока
func change_state(amount: int) -> void:
	player_state = clamp(player_state + amount, STATE_MIN, STATE_MAX)
	state_changed.emit(player_state)
	print("[GameState] State changed to %d" % player_state)

## Проверяет, позволяет ли текущее состояние сделать действие
func can_perform_action(required_state: int = 0) -> bool:
	return player_state >= required_state

# ==================== УПРАВЛЕНИЕ ТРЕКАМИ ====================
## Увеличивает значение трека
func add_track(track_type: String, amount: int = 1) -> void:
	if tracks.has(track_type):
		tracks[track_type] += amount
		track_changed.emit(track_type, tracks[track_type])
		print("[GameState] Track '%s' increased to %d" % [track_type, tracks[track_type]])

## Получает доминирующий трек (стиль игры)
func get_dominant_track() -> String:
	var max_value := 0
	var dominant := "observe"
	
	for track in tracks:
		if tracks[track] > max_value:
			max_value = tracks[track]
			dominant = track
	
	return dominant

# ==================== УПРАВЛЕНИЕ АРХЕТИПАМИ ====================
## Добавляет очки архетипу
func shift_archetype(archetype_name: String, intensity: float = 1.0) -> void:
	if archetypes.has(archetype_name):
		archetypes[archetype_name] += intensity
		archetype_shifted.emit(archetype_name, intensity)
		print("[GameState] Archetype '%s' shifted by %.2f" % [archetype_name, intensity])

## Получает доминирующий архетип (как игрок интерпретирует мир)
func get_dominant_archetype() -> String:
	var max_value := 0.0
	var dominant := "nihilist"  # дефолт
	
	for archetype in archetypes:
		if archetypes[archetype] > max_value:
			max_value = archetypes[archetype]
			dominant = archetype
	
	return dominant

# ==================== ФОТО-СИСТЕМА ====================
## Добавляет фото в дневной альбом
func take_photo(photo_data: Dictionary) -> bool:
	if daily_photos.size() >= MAX_PHOTOS_PER_DAY:
		return false
	
	daily_photos.append(photo_data)
	photo_taken.emit(photo_data)
	print("[GameState] Photo taken. Daily photos: %d/%d" % [daily_photos.size(), MAX_PHOTOS_PER_DAY])
	return true

## Выбирает одно фото для сохранения в память
func select_memory(index: int) -> Dictionary:
	if index < 0 or index >= daily_photos.size():
		return {}
	
	var selected := daily_photos[index]
	daily_photos.clear()
	memory.append(selected)
	memory_updated.emit(memory)
	return selected

# ==================== ЭХО-СИСТЕМА ====================
## Добавляет событие в эхо (если игрок пропустил момент)
func add_echo_event(event_id: String, event_data: Dictionary) -> void:
	echo_events.append({
		"id": event_id,
		"data": event_data,
		"day_added": current_day
	})
	print("[GameState] Echo event added: %s" % event_id)

## Проверяет и возвращает события эхо, которые должны проявиться
func check_echo_events() -> Array:
	var active_echos := []
	
	for echo in echo_events:
		# Эхо проявляется через 2-4 дня
		if current_day - echo["day_added"] >= 2:
			active_echos.append(echo)
	
	return active_echos

# ==================== СЕРИАЛИЗАЦИЯ ====================
## Сохраняет состояние в словарь (для сохранения игры)
func save_to_dict() -> Dictionary:
	return {
		"current_day": current_day,
		"player_state": player_state,
		"tracks": tracks,
		"archetypes": archetypes,
		"memory": memory,
		"echo_events": echo_events,
		"current_lens": current_lens
	}

## Загружает состояние из словаря
func load_from_dict(data: Dictionary) -> void:
	current_day = data.get("current_day", 1)
	player_state = data.get("player_state", 0)
	tracks = data.get("tracks", tracks)
	archetypes = data.get("archetypes", archetypes)
	memory = data.get("memory", [])
	echo_events = data.get("echo_events", [])
	current_lens = data.get("current_lens", "observation")
	print("[GameState] State loaded from save")
