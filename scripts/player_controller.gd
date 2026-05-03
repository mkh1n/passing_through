extends CharacterBody2D
## PlayerController - Управление игроком
## Игрок ЗАКРЕПЛЕН в центре экрана, двигаются ТОЛЬКО фон и объекты мира

signal player_moved(direction: float)
signal position_changed(new_position: float)

@export var speed: float = 500.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0

var is_moving: bool = false
var current_speed: float = 0.0
var world_position: float = 0.0  # Позиция в мире (не экранные координаты)
var event_trigger_distance: float = 800.0
var last_event_position: float = 0.0
var near_interactable: bool = false
var is_blocked: bool = false  # Блокировка движения во время событий


func _ready() -> void:
	# Игрок всегда в центре экрана
	position = Vector2(960, 540)


func _physics_process(delta: float) -> void:
	if not is_blocked:
		handle_movement(delta)
	else:
		current_speed = 0.0
		velocity.x = 0.0
	
	check_nearby_objects()
	move_and_slide()
	
	# Эмитим позицию для UI и других систем
	position_changed.emit(world_position)


## Обработка ввода и движения
func handle_movement(delta: float) -> void:
	var input_direction := Input.get_axis("move_left", "move_right")
	
	if input_direction != 0:
		is_moving = true
		# Плавное ускорение
		current_speed = move_toward(current_speed, input_direction * speed, acceleration * delta)
	else:
		is_moving = false
		# Плавная остановка (трение)
		current_speed = move_toward(current_speed, 0, friction * delta)
	
	# Игрок НЕ двигается визуально - его позиция фиксирована
	velocity.x = 0.0
	
	# Но мы отслеживаем "мировую" позицию
	if current_speed != 0:
		world_position += current_speed * delta
		# Эмитим направление движения фона (противоположное движению игрока)
		player_moved.emit(-current_speed)
	
	# Отражение спрайта по направлению движения
	if current_speed > 0:
		$Sprite2D.flip_h = false
	elif current_speed < 0:
		$Sprite2D.flip_h = true


func set_blocked(blocked: bool) -> void:
	is_blocked = blocked
	if blocked:
		current_speed = 0.0
		velocity.x = 0.0


## Проверка объектов рядом для взаимодействия
func check_nearby_objects() -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	# Проверяем область перед игроком (используем фиксированную позицию игрока)
	var query_from = global_position + Vector2(-20, 0)
	var query_to = global_position + Vector2(150, 0)
	
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(query_from, query_to)
	query.exclude = [self]
	query.collision_mask = 2 # world layer
	
	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		var collider: Node = result.collider
		near_interactable = collider.is_in_group("interactables")
	else:
		near_interactable = false


## Взаимодействие с объектами мира
func interact() -> void:
	if near_interactable and not is_blocked:
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + Vector2(150, 0)
		)
		query.exclude = [self]
		query.collision_mask = 2
		
		var result: Dictionary = space_state.intersect_ray(query)
		if result:
			var collider: Node = result.collider
			if collider.has_method("interact"):
				collider.interact()


## Проверка необходимости запуска события по мировой позиции
func should_trigger_event() -> bool:
	return abs(world_position - last_event_position) >= event_trigger_distance


## Сброс счетчика расстояния после события
func reset_event_counter() -> void:
	last_event_position = world_position
