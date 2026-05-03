extends Node2D
## ParallaxBackground - Управление параллакс фоном
## 8 слоев заднего фона, 2 слоя переднего плана
## Фон двигается в противоположную сторону от движения игрока

@export var player: CharacterBody2D

# Слои заднего фона (8 слоев)
@onready var bg_layers: Array[ParallaxLayer] = []
# Слои переднего плана (2 слоя)
@onready var fg_layers: Array[ParallaxLayer] = []

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
	
	print("ParallaxBackground готов. Слоев BG: ", bg_layers.size(), ", FG: ", fg_layers.size())


func _collect_parallax_layers() -> void:
	# Собираем слои заднего фона (motion_scale < 1.0) и переднего плана (motion_scale >= 1.0)
	for child in get_children():
		if child is ParallaxLayer:
			var motion_x = child.motion_scale.x
			if motion_x < 1.0:
				bg_layers.append(child)
			else:
				fg_layers.append(child)


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
		
		# Двигаем передний план с учетом их motion_scale  
		for layer in fg_layers:
			layer.motion_offset.x += movement_amount * layer.motion_scale.x
		
		# Двигаем объекты мира вместе с фоном
		if world_objects_container:
			for obj in world_objects_container.get_children():
				if obj.has_method("move_with_parallax"):
					obj.move_with_parallax(movement_amount)
		
		last_player_pos = player.global_position
