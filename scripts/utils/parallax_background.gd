## ParallaxBackground - Параллакс-фон для сцен путешествий
## Создаёт эффект глубины через многослойное движение
## Использует 2-3 слоя с разной скоростью

extends Node2D

# ==================== ЭКСПОРТИРУЕМЫЕ ПЕРЕМЕННЫЕ ====================
@export var layer1: Sprite2D  # Ближний слой (быстрее)
@export var layer2: Sprite2D  # Средний слой
@export var layer3: Sprite2D  # Дальний слой (медленнее)

@export var speed_multiplier_layer1: float = 1.0
@export var speed_multiplier_layer2: float = 0.5
@export var speed_multiplier_layer3: float = 0.2

# ==================== ПЕРЕМЕННЫЕ ====================
var scroll_speed: float = 100.0
var is_scrolling: bool = false
var offset_x: float = 0.0

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	print("[ParallaxBackground] Initialized")
	setup_layers()

# ==================== НАСТРОЙКА СЛОЁВ ====================
func setup_layers() -> void:
	# Настраиваем режимы текстуры для бесшовной прокрутки
	for layer in [layer1, layer2, layer3]:
		if layer:
			layer.texture.repeat_mode = CanvasItemTextureRepeatMode.REPEAT_ENABLED

# ==================== ОБНОВЛЕНИЕ ====================
func _process(delta: float) -> void:
	if is_scrolling:
		update_scroll(delta)

# ==================== ПРОКРУТКА ====================
## Обновляет позицию слоёв
func update_scroll(delta: float) -> void:
	offset_x += scroll_speed * delta
	
	if layer1:
		layer1.position.x = fmod(offset_x * speed_multiplier_layer1, get_viewport_rect().size.x)
	
	if layer2:
		layer2.position.x = fmod(offset_x * speed_multiplier_layer2, get_viewport_rect().size.x)
	
	if layer3:
		layer3.position.x = fmod(offset_x * speed_multiplier_layer3, get_viewport_rect().size.x)

## Запускает прокрутку
func start_scrolling(speed: float = 100.0) -> void:
	scroll_speed = speed
	is_scrolling = true
	print("[ParallaxBackground] Scrolling started at speed %.2f" % speed)

## Останавливает прокрутку
func stop_scrolling() -> void:
	is_scrolling = false
	print("[ParallaxBackground] Scrolling stopped")

## Устанавливает скорость прокрутки
func set_speed(speed: float) -> void:
	scroll_speed = speed

# ==================== ИНТЕГРАЦИЯ С ИГРОКОМ ====================
## Синхронизирует с движением игрока
func sync_with_player(player_velocity: float) -> void:
	scroll_speed = abs(player_velocity) * speed_multiplier_layer1

# ==================== ВИЗУАЛЬНЫЕ ЭФФЕКТЫ ====================
## Применяет цветовой фильтр на основе архетипа
func apply_archetype_filter(archetype: String) -> void:
	var modulate_color: = Color.WHITE
	
	match archetype:
		"euphoric":
			modulate_color = Color("#FFD700")
		"cynic":
			modulate_color = Color("#708090")
		"nihilist":
			modulate_color = Color("#2F4F4F")
		"healer":
			modulate_color = Color("#98FB98")
		"fleeing":
			modulate_color = Color("#4682B4")
		"obsessive":
			modulate_color = Color("#9370DB")
		"selfharm":
			modulate_color = Color("#8B0000")
	
	for layer in [layer1, layer2, layer3]:
		if layer:
			layer.modulate = modulate_color

## Добавляет эффект зерна (через CanvasModulate или PostProcessing)
func add_grain_effect(intensity: float = 0.1) -> void:
	# Можно добавить CanvasModulate узел для эффектов
	pass

# ==================== СБРОС ====================
## Сбрасывает позицию слоёв
func reset_position() -> void:
	offset_x = 0.0
	
	for layer in [layer1, layer2, layer3]:
		if layer:
			layer.position.x = 0.0
