extends Area2D
## BusStop - Автобусная остановка (интерактивный объект)
## Двигается вместе с параллаксом, можно сделать фото

signal photo_taken()

@export var stop_name: String = "Автобусная остановка"
@export var description: String = "Старая автобусная остановка с объявлениями"

var can_photo: bool = true
var parallax_speed: float = 1.0


func _ready() -> void:
	# Добавляем в группу интерактивных объектов
	add_to_group("interactables")


func move_with_parallax(speed: float) -> void:
	# Двигаем объект вместе с фоном
	global_position.x += speed * parallax_speed * 100


func can_take_photo() -> bool:
	return can_photo


func take_photo() -> void:
	if can_photo:
		photo_taken.emit()
		print("Фото сделано: ", stop_name)


func interact() -> void:
	print("Взаимодействие с остановкой: ", stop_name)
	print(description)
