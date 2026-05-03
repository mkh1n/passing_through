extends CharacterBody2D
## PlayerController - Управление игроком
## Игрок всегда в центре, двигается фон и объекты мира

signal player_moved(direction: float)

@export var speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

var is_moving: bool = false
var current_speed: float = 0.0
var total_distance: float = 0.0
var event_trigger_distance: float = 800.0
var last_event_position: float = 0.0


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	check_nearby_objects()
	move_and_slide()


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
	
	# Применяем движение к игроку
	velocity.x = current_speed
	
	# Отражение спрайта по направлению движения
	if current_speed > 0:
		$Sprite2D.flip_h = false
	elif current_speed < 0:
		$Sprite2D.flip_h = true
	
	# Отслеживаем пройденное расстояние для триггера событий
	if current_speed != 0:
		total_distance += abs(current_speed * delta)
		player_moved.emit(-current_speed)


## Проверка объектов рядом для взаимодействия
func check_nearby_objects() -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	# Проверяем область перед игроком
	var query_from = global_position + Vector2(-20, 0)
	var query_to = global_position + Vector2(100, 0)
	
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
	if near_interactable:
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + Vector2(100, 0)
		)
		query.exclude = [self]
		query.collision_mask = 2
		
		var result: Dictionary = space_state.intersect_ray(query)
		if result:
			var collider: Node = result.collider
			if collider.has_method("interact"):
				collider.interact()


## Проверка необходимости запуска события
func should_trigger_event() -> bool:
	return total_distance - last_event_position >= event_trigger_distance


## Сброс счетчика расстояния после события
func reset_event_counter() -> void:
	last_event_position = total_distance
