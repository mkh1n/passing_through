## MemorySystem - Система памяти и фото
## Управляет фотографированием, выбором фото для памяти, финальным коллажем
## Фото — это не скриншот, а интерпретация момента

extends Node

# ==================== СИГНАЛЫ ====================
signal photo_captured(photo_data: Dictionary)
signal photo_selected(index: int)
signal memory_finalized(memory: Array)
signal daily_review_started(photos: Array)

# ==================== ПЕРЕМЕННЫЕ ====================
# Максимум фото за день
const MAX_DAILY_PHOTOS := 3

# Текущие фото дня
var daily_photos: Array = []

# Типы восприятия для фото
enum PerceptionType {
	PEOPLE,        # Акцент на людях
	ENVIRONMENT,   # Акцент на окружении
	EMOTION,       # Акцент на эмоциях
	ABSTRACT       # Абстрактная композиция
}

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	print("[MemorySystem] Initialized")
	
	# Подключаемся к GameState
	if GameState:
		GameState.day_completed.connect(_on_day_completed)

# ==================== ФОТОГРАФИРОВАНИЕ ====================
## Создаёт фото из параметров сцены
func capture_photo(scene_context: Dictionary, perception_type: int, flavor_text: String = "") -> Dictionary:
	var photo: = {
		"id": "photo_%d_%d" % [GameState.current_day, daily_photos.size()],
		"day": GameState.current_day,
		"scene_id": scene_context.get("id", "unknown"),
		"perception_type": PerceptionType.keys()[perception_type],
		"flavor_text": flavor_text,
		"archetype_influence": GameState.get_dominant_archetype(),
		"lens": GameState.current_lens,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	daily_photos.append(photo)
	photo_captured.emit(photo)
	
	print("[MemorySystem] Photo captured: %s" % photo["id"])
	return photo

## Быстрое создание фото с выбором варианта (2-3 кадра восприятия)
func capture_with_variants(scene_context: Dictionary, variants: Array) -> Array:
	var photos: = []
	
	for variant in variants:
		var photo: = capture_photo(
			scene_context,
			variant.get("perception_type", PerceptionType.ENVIRONMENT),
			variant.get("flavor_text", "")
		)
		photos.append(photo)
		
		# Ограничиваем количество
		if daily_photos.size() >= MAX_DAILY_PHOTOS:
			break
	
	return photos

# ==================== ВЕЧЕРНИЙ ВЫБОР ====================
## Запускает вечерний обзор фото
func start_daily_review() -> void:
	if daily_photos.is_empty():
		# Если нет фото, создаём пустое воспоминание
		var empty_photo: = create_empty_memory()
		daily_photos.append(empty_photo)
	
	daily_review_started.emit(daily_photos)
	print("[MemorySystem] Daily review started with %d photos" % daily_photos.size())

## Выбирает фото для сохранения в долговременную память
func select_for_memory(index: int) -> Dictionary:
	if index < 0 or index >= daily_photos.size():
		push_error("[MemorySystem] Invalid photo index: %d" % index)
		return {}
	
	var selected: Dictionary = daily_photos[index]
	selected["selected"] = true
	
	# Добавляем в глобальную память через GameState
	GameState.memory.append(selected)
	
	# Удаляем невыбранные
	daily_photos.clear()
	
	photo_selected.emit(index)
	memory_finalized.emit(GameState.memory)
	
	print("[MemorySystem] Photo selected for memory: %s" % selected["id"])
	return selected

## Создаёт пустое воспоминание (если игрок ничего не фотографировал)
func create_empty_memory() -> Dictionary:
	return {
		"id": "empty_%d" % GameState.current_day,
		"day": GameState.current_day,
		"scene_id": "none",
		"perception_type": "ABSTRACT",
		"flavor_text": "Пустой кадр. Иногда важно то, чего ты не увидел.",
		"archetype_influence": GameState.get_dominant_archetype(),
		"lens": GameState.current_lens,
		"selected": true
	}

# ==================== ФИНАЛЬНЫЙ КОЛЛАЖ ====================
## Генерирует финальный коллаж из всех воспоминаний
func generate_final_collage() -> Dictionary:
	var collage: = {
		"total_days": GameState.current_day - 1,
		"total_memories": GameState.memory.size(),
		"photos": GameState.memory,
		"dominant_perception": get_dominant_perception(),
		"dominant_archetype": GameState.get_dominant_archetype(),
		"dominant_track": GameState.get_dominant_track(),
		"narrative_summary": generate_narrative_summary()
	}
	
	return collage

## Определяет доминирующий тип восприятия
func get_dominant_perception() -> String:
	var counts: = {}
	
	for photo in GameState.memory:
		var ptype: = photo.get("perception_type", "ENVIRONMENT")
		counts[ptype] = counts.get(ptype, 0) + 1
	
	var max_count: = 0
	var dominant: = "ENVIRONMENT"
	
	for ptype in counts:
		if counts[ptype] > max_count:
			max_count = counts[ptype]
			dominant = ptype
	
	return dominant

## Генерирует текстовое резюме игры
func generate_narrative_summary() -> String:
	var archetype: = GameState.get_dominant_archetype()
	var track: = GameState.get_dominant_track()
	var perception: = get_dominant_perception()
	
	var summaries: = {
		"euphoric": "Ты видел мир в розовых очках. Каждый момент был наполнен светом.",
		"obsessive": "Ты зацикливался на деталях. Мелочи становились важным.",
		"cynic": "Ты смотрел на мир с подозрением. Ничто не было таким, каким казалось.",
		"fleeing": "Ты бежал от моментов. Но они всё равно настигали тебя.",
		"healer": "Ты искал исцеление в каждом встречном. Мир стал мягче.",
		"nihilist": "Ничто не имело значения. И в этом была свобода.",
		"selfharm": "Ты причинял себе боль снова и снова. Но продолжал идти."
	}
	
	return summaries.get(archetype, "Твой путь уникален.")

# ==================== АНАЛИЗ ПАМЯТИ ====================
## Анализирует паттерны выбора игрока
func analyze_memory_patterns() -> Dictionary:
	var analysis: = {
		"people_focus": 0,
		"environment_focus": 0,
		"emotion_focus": 0,
		"abstract_focus": 0,
		"positive_moments": 0,
		"negative_moments": 0
	}
	
	for photo in GameState.memory:
		var ptype: = photo.get("perception_type", "ENVIRONMENT")
		
		match ptype:
			"PEOPLE":
				analysis["people_focus"] += 1
			"ENVIRONMENT":
				analysis["environment_focus"] += 1
			"EMOTION":
				analysis["emotion_focus"] += 1
			"ABSTRACT":
				analysis["abstract_focus"] += 1
		
		# Анализ тональности по тексту
		var text: = photo.get("flavor_text", "").to_lower()
		if any_word_in_text(text, ["свет", "тепло", "радость", "смех"]):
			analysis["positive_moments"] += 1
		elif any_word_in_text(text, ["тьма", "холод", "боль", "страх"]):
			analysis["negative_moments"] += 1
	
	return analysis

## Проверяет наличие слов в тексте
func any_word_in_text(text: String, words: Array) -> bool:
	for word in words:
		if text.contains(word):
			return true
	return false

# ==================== СОБЫТИЯ ====================
func _on_day_completed(day_number: int) -> void:
	start_daily_review()

# ==================== СЕРИАЛИЗАЦИЯ ====================
## Сохраняет данные памяти
func save_to_dict() -> Dictionary:
	return {
		"daily_photos": daily_photos,
		"memory": GameState.memory
	}

## Загружает данные памяти
func load_from_dict(data: Dictionary) -> void:
	daily_photos = data.get("daily_photos", [])
	# GameState.memory загружается отдельно
