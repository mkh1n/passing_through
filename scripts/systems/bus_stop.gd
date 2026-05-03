extends Area2D
## BusStop - Автобусная остановка (интерактивный объект)
## Двигается вместе с параллаксом, событие появляется при приближении
## Начальная позиция: x=1500, игрок начинает на x=960, нужно пройти ~540 пикселей

@export var stop_name: String = "Автобусная остановка"
@export var description: String = "Старая автобусная остановка с объявлениями"

var parallax_speed: float = 1.0
var event_triggered: bool = false
var initial_world_position: float = 1500.0  # Мировая позиция остановки


func _ready() -> void:
	# Добавляем в группу интерактивных объектов
	add_to_group("interactables")
	# Устанавливаем начальную позицию
	position.x = initial_world_position
	print("Остановка создана на позиции: ", position.x)


func move_with_parallax(speed: float) -> void:
	# Двигаем объект вместе с фоном (скорость отрицательная когда игрок идет вправо)
	position.x += speed


func interact() -> void:
	if not event_triggered:
		event_triggered = true
		print("Взаимодействие с остановкой: ", stop_name)
		print(description)
		# Запускаем событие через EventManager
		trigger_event()


func trigger_event() -> void:
	# Блокируем игрока перед запуском события
	var player = get_node("../../Player")
	if player and player.has_method("set_blocked"):
		player.set_blocked(true)
	
	# Запускаем событие остановки
	var event_data = {
		"id": "stopa_001",
		"title": "Остановка",
		"context": "остановка",
		"emotion": "ожидание",
		"text": "Ты стоишь на остановке. Рядом человек в серой куртке смотрит на телефон. Автобуса нет уже 20 минут.",
		"day_min": 1,
		"day_max": 5,
		"repeatable": false,
		"choices": [
			{
				"text": "Посмотреть на человека",
				"state_change": 0,
				"track_changes": {"observe": 1},
				"archetype_shifts": {"obsessive": 1}
			},
			{
				"text": "Заговорить",
				"state_change": 1,
				"track_changes": {"connect": 1, "action": 1},
				"archetype_shifts": {"euphoric": 1, "healer": 1}
			},
			{
				"text": "Игнорировать",
				"state_change": 0,
				"track_changes": {"observe": 1},
				"archetype_shifts": {"nihilist": 1, "fleeing": 1},
				"echo_trigger": "stopa_001_echo"  # Если проигнорируем, появится эхо позже
			}
		]
	}
	EventManager.start_event(event_data)
