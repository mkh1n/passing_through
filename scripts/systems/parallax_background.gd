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
@onready var world_objects_container: Node2D = $WorldObjects

var base_speed: float = 1.0


func _ready() -> void:
	# Находим все слои параллакса
	_collect_parallax_layers()
	
	# Подключаемся к сигналу игрока
	if player == null:
		player = get_node_or_null("../Player")
	
	if player and player.has_signal("player_moved"):
		player.player_moved.connect(_on_player_moved)
	
	print("ParallaxBackground готов. Слоев BG: ", bg_layers.size(), ", FG: ", fg_layers.size())


func _collect_parallax_layers() -> void:
	# Собираем слои заднего фона (motion_scale < 1.0)
	for child in get_children():
		if child is ParallaxLayer:
			var motion_x = child.motion_scale.x
			if motion_x < 1.0:
				bg_layers.append(child)
			else:
				fg_layers.append(child)
	
	print("ParallaxBackground: Найдено слоев заднего фона: ", bg_layers.size())
	print("ParallaxBackground: Найдено слоев переднего плана: ", fg_layers.size())


func _on_player_moved(direction: float) -> void:
	# Двигаем все слои в направлении opposite to player movement
	# direction уже отрицательный когда игрок идет вправо
	
	var speed_multiplier = base_speed * direction * 0.5
	
	# Двигаем задний фон (медленнее)
	for layer in bg_layers:
		layer.motion_offset.x += speed_multiplier * layer.motion_scale.x
		# Сбрасываем offset чтобы избежать проблем с большими числами
		if abs(layer.motion_offset.x) > 10000:
			layer.motion_offset.x = fmod(layer.motion_offset.x, 1920)
	
	# Двигаем передний план (быстрее)
	for layer in fg_layers:
		layer.motion_offset.x += speed_multiplier * layer.motion_scale.x
		if abs(layer.motion_offset.x) > 10000:
			layer.motion_offset.x = fmod(layer.motion_offset.x, 1920)
	
	# Двигаем объекты мира
	if world_objects_container:
		for obj in world_objects_container.get_children():
			if obj.has_method("move_with_parallax"):
				obj.move_with_parallax(speed_multiplier)
