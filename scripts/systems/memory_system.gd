extends Node
## MemorySystem - Система памяти и фото (Autoload)
## Управляет фото-системой: генерация кадров восприятия, выбор памяти, финальный коллаж

signal photo_taken(photo_data: Dictionary)
signal memory_selected(photo_data: Dictionary)
signal daily_summary_ready(photos: Array[Dictionary], selected_index: int)

# Фото за текущий день (2-3 варианта)
var daily_photos: Array[Dictionary] = []

# Выбранное фото дня (память)
var selected_memory: Dictionary = {}

# Вся память игры (массив выбранных фото)
var full_memory: Array[Dictionary] = []

# Статистика типов восприятия
var perception_stats: Dictionary = {
	"participation": 0,
	"observation": 0,
	"connection": 0
}


func _ready() -> void:
	pass


## Начало нового дня
func start_new_day() -> void:
	daily_photos.clear()
	selected_memory = {}


## Генерация вариантов фото для события
func generate_photo_options(event_data: Dictionary, lens: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	
	var base_context: String = event_data.get("context", "unknown")
	var emotion: String = event_data.get("emotion", "neutral")
	
	# Генерация 2-3 вариантов в зависимости от линзы
	match lens:
		"participation":
			options = [
				create_photo("Я в центре событий", base_context, emotion, "participation"),
				create_photo("Мои руки/действие", base_context, emotion, "participation")
			]
		"observation":
			options = [
				create_photo("Со стороны, как наблюдатель", base_context, emotion, "observation"),
				create_photo("Пустое пространство", base_context, "empty", "observation")
			]
		"connection":
			options = [
				create_photo("Я и другой человек вместе", base_context, emotion, "connection"),
				create_photo("Взгляд другого", base_context, emotion, "connection")
			]
	
	# Добавление третьего варианта иногда
	if randf() > 0.5:
		options.append(create_photo("Абстрактная деталь", base_context, emotion, lens))
	
	return options


## Создание структуры фото
func create_photo(description: String, context: String, emotion: String, perception_type: String) -> Dictionary:
	return {
		"description": description,
		"context": context,
		"emotion": emotion,
		"perception_type": perception_type,
		"day": GameState.current_day,
		"timestamp": Time.get_unix_time_from_system(),
		"archetype_influence": GameState.get_dominant_archetype()
	}


## Игрок делает фото (добавляет в ежедневные)
func take_photo(photo_data: Dictionary) -> void:
	if daily_photos.size() < 3:
		daily_photos.append(photo_data)
		photo_taken.emit(photo_data)
		
		# Обновление статистики восприятия
		var ptype: String = photo_data.get("perception_type", "observation")
		if ptype in perception_stats:
			perception_stats[ptype] += 1


## Выбор финального фото дня для памяти
func select_daily_memory(index: int) -> Dictionary:
	if index < 0 or index >= daily_photos.size():
		return {}
	
	selected_memory = daily_photos[index]
	full_memory.append(selected_memory)
	
	memory_selected.emit(selected_memory)
	daily_summary_ready.emit(daily_photos, index)
	
	# Очистка дневных фото (кроме выбранного)
	daily_photos.clear()
	
	return selected_memory


## Получение типа доминирующего восприятия
func get_dominant_perception() -> String:
	var max_count: int = 0
	var dominant: String = "observation"
	
	for ptype in perception_stats.keys():
		if perception_stats[ptype] > max_count:
			max_count = perception_stats[ptype]
			dominant = ptype
	
	return dominant


## Анализ памяти для финала
func analyze_memory() -> Dictionary:
	var analysis: Dictionary = {
		"total_days": full_memory.size(),
		"perception_distribution": perception_stats.duplicate(),
		"emotion_frequency": {},
		"context_frequency": {},
		"archetype_evolution": [],
		"dominant_perception": get_dominant_perception()
	}
	
	# Подсчёт эмоций и контекстов
	for photo in full_memory:
		var emotion: String = photo.get("emotion", "neutral")
		var context: String = photo.get("context", "unknown")
		
		analysis.emotion_frequency[emotion] = analysis.emotion_frequency.get(emotion, 0) + 1
		analysis.context_frequency[context] = analysis.context_frequency.get(context, 0) + 1
		analysis.archetype_evolution.append(photo.get("archetype_influence", "nihilist"))
	
	return analysis


## Получение всех фото для финального коллажа
func get_memory_collage() -> Array[Dictionary]:
	return full_memory


## Сброс памяти (для новой игры)
func reset_memory() -> void:
	daily_photos.clear()
	selected_memory = {}
	full_memory.clear()
	perception_stats = {
		"participation": 0,
		"observation": 0,
		"connection": 0
	}


## Сохранение памяти в файл (опционально)
func save_memory_to_file(path: String = "user://memory_save.json") -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var data: Dictionary = {
			"full_memory": full_memory,
			"perception_stats": perception_stats
		}
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Память сохранена в: ", path)


## Загрузка памяти из файла (опционально)
func load_memory_from_file(path: String = "user://memory_save.json") -> bool:
	if not FileAccess.file_exists(path):
		return false
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string: String = file.get_as_text()
		var json: JSON = JSON.new()
		var error: Error = json.parse(json_string)
		if error == OK:
			var data: Variant = json.data
			full_memory = data.get("full_memory", [])
			perception_stats = data.get("perception_stats", perception_stats)
			file.close()
			return true
		file.close()
	
	return false
