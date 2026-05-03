extends Node
## GameState - Глобальное состояние игры (Autoload)
## Хранит все данные сессии: треки, архетипы, состояние, день, эхо-события

signal state_changed(new_state: int)
signal tracks_updated(action: int, observe: int, connect: int)
signal archetype_shifted(archetype: String, value: int)
signal day_started(day: int)
signal echo_triggered(event_id: String)

# Треки влияния (что игрок делал)
var action_track: int = 0
var observe_track: int = 0
var connect_track: int = 0

# Архетипы (как игрок делал) - стиль интерпретации
var archetypes: Dictionary = {
	"euphoric": 0,
	"obsessive": 0,
	"cynic": 0,
	"fleeing": 0,
	"healer": 0,
	"nihilist": 0,
	"selfharm": 0
}

# Состояние игрока (-2 до +2)
# Влияет на доступные выборы и тон событий
var state: int = 0

# Текущий день (1-15)
var current_day: int = 1

# Линза восприятия (меняет интерпретацию сцен)
var current_lens: String = "observation" # participation, observation, connection

# Эхо-события (пропущенные моменты, которые вернутся)
var echo_events: Array[String] = []

# Активное событие (текущая сцена)
var current_event: Dictionary = {}

# Фото за текущий день (удалено - фото механика вырезана)
# var daily_photos: Array[Dictionary] = []

# Сохранённая память (выбранное фото в конце дня) - удалено
# var memory: Array[Dictionary] = []


func _ready() -> void:
	pass


## Инициализация новой игры
func start_new_game() -> void:
	action_track = 0
	observe_track = 0
	connect_track = 0
	
	for key in archetypes.keys():
		archetypes[key] = 0
	
	state = 0
	current_day = 1
	echo_events.clear()
	# daily_photos.clear() - удалено
	# memory.clear() - удалено
	current_lens = "observation"
	
	day_started.emit(current_day)


## Обновление состояния
func update_state(delta: int) -> void:
	state = clamp(state + delta, -2, 2)
	state_changed.emit(state)


## Добавление очков к треку
func add_to_track(track_type: String, amount: int = 1) -> void:
	match track_type:
		"action":
			action_track += amount
		"observe":
			observe_track += amount
		"connect":
			connect_track += amount
	
	tracks_updated.emit(action_track, observe_track, connect_track)


## Изменение архетипа
func shift_archetype(archetype_name: String, value: int = 1) -> void:
	if archetype_name in archetypes:
		archetypes[archetype_name] += value
		archetype_shifted.emit(archetype_name, value)


## Получение доминирующего архетипа
func get_dominant_archetype() -> String:
	var max_value: int = -999
	var dominant: String = "nihilist"
	
	for key in archetypes.keys():
		if archetypes[key] > max_value:
			max_value = archetypes[key]
			dominant = key
	
	return dominant


## Добавление эхо-события
func add_echo(event_id: String) -> void:
	if event_id not in echo_events:
		echo_events.append(event_id)
		echo_triggered.emit(event_id)


## Удаление эхо-события после проявления
func remove_echo(event_id: String) -> void:
	echo_events.erase(event_id)


## Начало нового дня
func start_next_day() -> void:
	current_day += 1
	# daily_photos.clear() - удалено
	
	if current_day <= 15:
		day_started.emit(current_day)


## Добавление фото за день (удалено)
# func add_daily_photo(photo_data: Dictionary) -> void:
# 	if daily_photos.size() < 3:
# 		daily_photos.append(photo_data)


## Выбор финального фото для памяти (удалено)
# func select_memory(index: int) -> Dictionary:
# 	if index < 0 or index >= daily_photos.size():
# 		return {}
# 	
# 	var selected: Dictionary = daily_photos[index]
# 	daily_photos.clear()
# 	memory.append(selected)
# 	return selected


## Получение всех данных состояния для сохранения
func get_save_data() -> Dictionary:
	return {
		"action_track": action_track,
		"observe_track": observe_track,
		"connect_track": connect_track,
		"archetypes": archetypes,
		"state": state,
		"current_day": current_day,
		"echo_events": echo_events,
		# "memory": memory, - удалено
		"current_lens": current_lens
	}


## Загрузка данных из сохранения
func load_save_data(data: Dictionary) -> void:
	action_track = data.get("action_track", 0)
	observe_track = data.get("observe_track", 0)
	connect_track = data.get("connect_track", 0)
	archetypes = data.get("archetypes", archetypes)
	state = data.get("state", 0)
	current_day = data.get("current_day", 1)
	echo_events = data.get("echo_events", [])
	# memory = data.get("memory", []) - удалено
	current_lens = data.get("current_lens", "observation")
