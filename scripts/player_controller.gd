extends CharacterBody2D
## PlayerController - Управление игроком
## Движение, ускорение, взаимодействие с миром

@export var speed: float = 200.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

var is_moving: bool = false
var current_speed: float = 0.0


func _physics_process(delta: float) -> void:
	handle_movement(delta)
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
	
	velocity.x = current_speed
	
	# Отражение спрайта по направлению движения
	if current_speed > 0:
		$Sprite2D.flip_h = false
	elif current_speed < 0:
		$Sprite2D.flip_h = true


## Взаимодействие с объектами мира
func interact() -> void:
	# Проверка на наличие интерактивных объектов рядом
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(current_speed, 0).normalized() * 50
	)
	query.exclude = [self]
	
	var result := space_state.intersect_ray(query)
	if result:
		var collider := result.collider
		if collider.has_method("interact"):
			collider.interact()


## Запуск мини-игры (если требуется событием)
func trigger_minigame(minigame_type: String, difficulty: float) -> void:
	# Сигнал для UI/менеджера мини-игр
	print("Мини-игра запрошена: ", minigame_type, " сложность: ", difficulty)


## Фото-триггер (нажатие P во время события)
func trigger_photo() -> void:
	# Сигнал для системы памяти
	print("Фото триггер активирован")
