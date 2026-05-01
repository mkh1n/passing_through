## PlayerController - Управление движением игрока
## Обрабатывает перемещение, ускорение, параллакс-эффекты
## Используется в сценах путешествий между локациями

extends CharacterBody2D

# ==================== СИГНАЛЫ ====================
signal arrived_at_destination
signal movement_started
signal movement_stopped

# ==================== КОНСТАНТЫ ====================
const BASE_SPEED := 100.0
const ACCELERATION := 400.0
const FRICTION := 600.0
const MAX_SPEED_MULTIPLIER := 2.0

# ==================== ЭКСПОРТИРУЕМЫЕ ПЕРЕМЕННЫЕ ====================
@export var speed: float = BASE_SPEED
@export var acceleration: float = ACCELERATION
@export var friction: float = FRICTION

# Спрайт игрока (плейсхолдер)
@export var sprite: Sprite2D

# Анимация движения
@export var animation_player: AnimationPlayer

# ==================== ПЕРЕМЕННЫЕ СОСТОЯНИЯ ====================
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO
var movement_progress: float = 0.0
var current_speed_multiplier: float = 1.0

# Для параллакс-фона
var parallax_offset: float = 0.0

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	print("[PlayerController] Initialized")
	
	if sprite:
		sprite.centered = true

# ==================== ОБНОВЛЕНИЕ ====================
func _physics_process(delta: float) -> void:
	if is_moving:
		handle_movement(delta)

# ==================== ДВИЖЕНИЕ ====================
## Начинает движение к целевой позиции
func start_movement(target: Vector2) -> void:
	target_position = target
	is_moving = true
	movement_progress = 0.0
	current_speed_multiplier = 1.0
	
	movement_started.emit()
	print("[PlayerController] Started movement to %s" % target)

## Останавливает движение
func stop_movement() -> void:
	is_moving = false
	velocity = Vector2.ZERO
	
	movement_stopped.emit()
	print("[PlayerController] Movement stopped")

## Обрабатывает физику движения
func handle_movement(delta: float) -> void:
	# Вычисляем направление
	var direction: = (target_position - global_position).normalized()
	
	if direction == Vector2.ZERO:
		stop_movement()
		arrived_at_destination.emit()
		return
	
	# Ускорение
	if is_moving:
		velocity = velocity.move_toward(direction * speed * current_speed_multiplier, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Двигаемся
	move_and_slide()
	
	# Обновляем прогресс
	var distance: = target_position.distance_to(global_position)
	if distance < 5.0:  # Порог прибытия
		global_position = target_position
		stop_movement()
		arrived_at_destination.emit()
		print("[PlayerController] Arrived at destination")
	
	# Параллакс-эффект
	update_parallax(delta)
	
	# Поворот спрайта по направлению движения
	if sprite and direction.x != 0:
		sprite.flip_h = direction.x < 0

## Обновляет параллакс-смещение
func update_parallax(delta: float) -> void:
	if velocity.length() > 0:
		parallax_offset += velocity.x * delta * 0.5
		position.x = fposmod(parallax_offset, 100.0)  # Циклическое смещение

# ==================== УСКОРЕНИЕ ====================
## Включает ускорение (спринт)
func activate_boost() -> void:
	current_speed_multiplier = MAX_SPEED_MULTIPLIER
	print("[PlayerController] Boost activated")

## Выключает ускорение
func deactivate_boost() -> void:
	current_speed_multiplier = 1.0
	print("[PlayerController] Boost deactivated")

# ==================== ВВОД (для отладки/проверки) ====================
func _input(event: InputEvent) -> void:
	# Только для тестирования в редакторе
	if not Engine.is_editor_hint():
		if event.is_action_pressed("ui_accept"):
			if not is_moving:
				start_movement(get_viewport().get_mouse_position())
		
		if event.is_action_pressed("ui_cancel"):
			stop_movement()

# ==================== АНИМАЦИИ ====================
## Проигрывает анимацию начала движения
func play_move_animation() -> void:
	if animation_player and animation_player.has_animation("move"):
		animation_player.play("move")

## Проигрывает анимацию остановки
func play_stop_animation() -> void:
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

# ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
## Получает текущий прогресс движения (0.0 - 1.0)
func get_movement_progress() -> float:
	if target_position == Vector2.ZERO:
		return 0.0
	
	var total_distance: = target_position.distance_to(global_position)
	if total_distance == 0:
		return 1.0
	
	return 1.0 - (global_position.distance_to(target_position) / total_distance)

## Сбрасывает позицию
func reset_position(new_position: Vector2) -> void:
	global_position = new_position
	stop_movement()

# ==================== ИНТЕГРАЦИЯ С GameState ====================
## Движение влияет на трек action
func on_journey_completed() -> void:
	if GameState:
		GameState.add_track("action", 1)
