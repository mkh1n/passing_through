extends ParallaxBackground
## ParallaxBackground - Управление параллакс фоном
## 8 слоев заднего фона (без переднего плана)
## Фон двигается в противоположную сторону от движения игрока

@export var player: CharacterBody2D

# Слои заднего фона (8 слоев)
@onready var bg_layers: Array[ParallaxLayer] = []

# Объекты мира (остановки, предметы)
@onready var world_objects_container: Node2D = $WorldObjects if has_node("WorldObjects") else null

var base_speed: float = 1.0
var last_player_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Находим все слои параллакса
	_collect_parallax_layers()
	
	# Находим игрока
	if player == null:
		player = get_node_or_null("../Player")
	
	if player:
		last_player_pos = player.global_position
	
	# Устанавливаем scroll_offset в 0 для корректной работы
	scroll_offset = Vector2.ZERO
	
	# Проверяем что слои имеют правильный размер и позицию
	for layer in bg_layers:
		for child in layer.get_children():
			if child is Sprite2D:
				# Убеждаемся что спрайты позиционированы правильно
				if child.position.x < 0:
					child.position.x = 0
	
	print("ParallaxBackground готов. Слоев BG: ", bg_layers.size())


func _collect_parallax_layers() -> void:
	# Собираем все слои как задний фон (motion_scale < 1.0)
	for child in get_children():
		if child is ParallaxLayer:
			bg_layers.append(child)
	
	# Сортируем слои по z-index (чем меньше номер слоя, тем выше он визуально)
	bg_layers.sort_custom(func(a, b): return a.z_index > b.z_index)


func _process(_delta: float) -> void:
	if not player:
		return
	
	# Вычисляем движение игрока
	var player_movement = player.global_position - last_player_pos
	
	if abs(player_movement.x) > 0.1:
		# Двигаем все слои параллакса вручную для правильного эффекта
		# Игрок движется вправо -> фон движется влево (отрицательное значение)
		var movement_amount = -player_movement.x
		
		# Двигаем задний фон с учетом их motion_scale
		for layer in bg_layers:
			layer.motion_offset.x += movement_amount * layer.motion_scale.x
		
		# Двигаем объекты мира вместе с фоном
		if world_objects_container:
			for obj in world_objects_container.get_children():
				if obj.has_method("move_with_parallax"):
					obj.move_with_parallax(movement_amount)
		
		last_player_pos = player.global_position
