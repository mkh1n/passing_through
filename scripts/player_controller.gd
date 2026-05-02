extends CharacterBody2D
## PlayerController - Управление игроком
## Игрок всегда в центре экрана, двигается фон и объекты мира

signal player_moved(direction: float)
signal photo_requested()

@export var speed: float = 200.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

var is_moving: bool = false
var current_speed: float = 0.0
var can_take_photo: bool = false
var near_interactable: bool = false
var start_position: Vector2


func _ready() -> void:
	# Сохраняем начальную позицию игрока (центр экрана)
	start_position = position
	# Игрок всегда в центре - его позиция не меняется по X
	position.x = 960


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	check_nearby_objects()
	# Не вызываем move_and_slide() так как игрок не двигается физически
	# Движение эмулируется через сигнал для фона


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
	# Когда игрок идет вправо (positive), фон движется влево (negative)
	if current_speed != 0:
		player_moved.emit(current_speed)


## Проверка объектов рядом для взаимодействия
func check_nearby_objects() -> void:
	# Проверяем расстояние до объектов мира (автобусная остановка и т.д.)
	near_interactable = false
	can_take_photo = false
	
	# Находим все объекты в группе interactables
	var tree = get_tree()
	if tree:
		for node in tree.get_nodes_in_group("interactables"):
			if node is Area2D or node.has_node("Sprite2D"):
				var obj_pos: Vector2 = node.global_position
				var distance = abs(obj_pos.x - global_position.x)
				
				# Если объект близко (в пределах 150 пикселей)
				if distance < 150:
					near_interactable = true
					if node.has_method("can_take_photo"):
						can_take_photo = node.can_take_photo()


## Взаимодействие с объектами мира
func interact() -> void:
	if near_interactable:
		var tree = get_tree()
		if tree:
			for node in tree.get_nodes_in_group("interactables"):
				var obj_pos: Vector2 = node.global_position
				var distance = abs(obj_pos.x - global_position.x)
				if distance < 150:
					if node.has_method("interact"):
						node.interact()
					break


## Запуск мини-игры (если требуется событием)
func trigger_minigame(minigame_type: String, difficulty: float) -> void:
	print("Мини-игра запрошена: ", minigame_type, " сложность: ", difficulty)


## Фото-триггер (нажатие Q во время события)
func trigger_photo() -> void:
	if can_take_photo:
		photo_requested.emit()
		print("Фото триггер активирован")
