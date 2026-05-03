extends ParallaxBackground
## ParallaxBackground - Управление параллакс фоном
## 8 слоев заднего фона (без переднего плана)
## Фон двигается в противоположную сторону от движения игрока
## Z-index: чем МЕНЬШЕ номер слоя, тем ВЫШЕ он визуально (слой 1 выше слоя 8)

@export var player: CharacterBody2D

# Слои заднего фона (8 слоев)
@onready var bg_layers: Array[ParallaxLayer] = []

# Объекты мира (остановки, предметы)
@onready var world_objects_container: Node2D = $WorldObjects if has_node("WorldObjects") else null

var base_speed: float = 1.0
var accumulated_movement: float = 0.0


func _ready() -> void:
	# Находим все слои параллакса
	_collect_parallax_layers()
	
	# Находим игрока
	if player == null:
		player = get_node_or_null("../Player")
	
	# Устанавливаем scroll_offset в 0 для корректной работы
	scroll_offset = Vector2.ZERO
	
	# Настраиваем Z-index: чем меньше номер слоя, тем выше он визуально
	# Слой 1 (z_index=7) должен быть выше слоя 8 (z_index=0)
	_setup_layer_z_indices()
	
	print("ParallaxBackground готов. Слоев BG: ", bg_layers.size())


func _collect_parallax_layers() -> void:
	# Собираем все слои как задний фон (motion_scale < 1.0)
	for child in get_children():
		if child is ParallaxLayer:
			bg_layers.append(child)
	
	# Сортируем слои по motion_scale (от меньшего к большему)
	# Меньший motion_scale = более дальний план = ниже z_index
	bg_layers.sort_custom(func(a, b): return a.motion_scale.x < b.motion_scale.x)


func _setup_layer_z_indices() -> void:
	# Настраиваем Z-index правильно: чем меньше номер слоя, тем выше он визуально
	# Layer1 (motion_scale 0.1) -> z_index = 7 (самый верхний из фонов)
	# Layer8 (motion_scale 0.8) -> z_index = 0 (самый нижний из фонов)
	for i in range(bg_layers.size()):
		var layer = bg_layers[i]
		layer.z_index = bg_layers.size() - 1 - i
	
	print("Z-indices настроены:")
	for layer in bg_layers:
		print("  Layer motion_scale: ", layer.motion_scale.x, " -> z_index: ", layer.z_index)


func _process(delta: float) -> void:
	if not player:
		return
	
	# Получаем скорость движения от игрока через сигнал
	# Игрок эмитит player_moved с направлением (-speed когда идет вправо)
	var player_speed = 0.0
	if player.has_signal("player_moved"):
		# Используем накопленное движение из player_controller
		player_speed = player.current_speed
	
	if abs(player_speed) > 0.1:
		# Двигаем все слои параллакса
		# Игрок идет вправо (positive speed) -> фон движется влево (negative offset)
		var movement_amount = -player_speed * delta
		
		# Двигаем задний фон с учетом их motion_scale
		for layer in bg_layers:
			layer.motion_offset.x += movement_amount * layer.motion_scale.x
		
		# Двигаем объекты мира вместе с фоном
		if world_objects_container:
			for obj in world_objects_container.get_children():
				if obj.has_method("move_with_parallax"):
					obj.move_with_parallax(movement_amount)
