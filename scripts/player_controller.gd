extends CharacterBody2D
## PlayerController - Управление игроком
## Игрок всегда в центре, двигается фон и объекты мира

signal player_moved(direction: float)
signal photo_requested()

@export var speed: float = 200.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

var is_moving: bool = false
var current_speed: float = 0.0
var can_take_photo: bool = false
var near_interactable: bool = false


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
	
	# Игрок не двигается физически, но мы передаем скорость для параллакса
	# velocity.x = current_speed
	
	# Отражение спрайта по направлению движения
	if current_speed > 0:
		$Sprite2D.flip_h = false
	elif current_speed < 0:
		$Sprite2D.flip_h = true
	
	# Сигнал для движения фона (противоположное направление)
	if current_speed != 0:
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
		near_interactable = collider.is_in_group("interactables") or collider.has_method("can_take_photo")
		can_take_photo = collider.has_method("can_take_photo") and collider.can_take_photo()
	else:
		near_interactable = false
		can_take_photo = false


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


## Запуск мини-игры (если требуется событием)
func trigger_minigame(minigame_type: String, difficulty: float) -> void:
	print("Мини-игра запрошена: ", minigame_type, " сложность: ", difficulty)


## Фото-триггер (нажатие Q во время события)
func trigger_photo() -> void:
	if can_take_photo:
		photo_requested.emit()
		print("Фото триггер активирован")
