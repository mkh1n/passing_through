extends CanvasLayer
## UIController - Управление интерфейсом
## Отображение событий, выборов, debug лог

signal choice_made(index: int)
signal day_completed()

@onready var event_panel: Panel = $EventPanel
@onready var event_text: RichTextLabel = $EventPanel/EventText
@onready var choices_container: VBoxContainer = $EventPanel/ChoicesContainer
@onready var state_label: Label = $StateLabel
@onready var day_label: Label = $DayLabel
@onready var archetype_label: Label = $ArchetypeLabel
@onready var debug_label: Label = $DebugLabel

var current_event: Dictionary = {}
var game_started: bool = false
var show_ui: bool = false
var player_near_interactable: bool = false

# Debug лог для отслеживания выборов и флагов
var debug_log: Array[String] = []


func _ready() -> void:
	hide_all_panels()
	setup_signals()
	
	if not has_node("StartButton"):
		create_start_button()
	
	toggle_ui_visibility(false)
	
	var start_button = get_node_or_null("StartButton")
	if start_button:
		start_button.show()


func create_start_button() -> void:
	var button = Button.new()
	button.name = "StartButton"
	button.text = "НАЧАТЬ ИГРУ"
	button.custom_minimum_size = Vector2(200, 60)
	button.position = Vector2(860, 400)
	button.pressed.connect(_on_start_button_pressed)
	add_child(button)


func toggle_ui_visibility(visible: bool) -> void:
	show_ui = visible
	
	if has_node("DayLabel"):
		$DayLabel.visible = visible
	if has_node("StateLabel"):
		$StateLabel.visible = visible
	if has_node("ArchetypeLabel"):
		$ArchetypeLabel.visible = visible
	if has_node("DebugLabel"):
		$DebugLabel.visible = visible


func setup_signals() -> void:
	EventManager.event_loaded.connect(_on_event_loaded)
	EventManager.choices_presented.connect(_on_choices_presented)
	EventManager.event_completed.connect(_on_event_completed)
	GameState.state_changed.connect(_on_state_changed)
	GameState.day_started.connect(_on_day_started)
	GameManager.day_phase_changed.connect(_on_phase_changed)
	
	var player = get_node_or_null("../Player")
	if player and player.has_signal("player_moved"):
		player.player_moved.connect(_on_player_moved)


func _input(event: InputEvent) -> void:
	if not game_started:
		return
	
	if event.is_action_pressed("interact") and player_near_interactable and event_panel.visible == false:
		var player = get_node_or_null("../Player")
		if player and player.has_method("interact"):
			player.interact()


func hide_all_panels() -> void:
	event_panel.hide()


func _on_player_moved(direction: float) -> void:
	var player = get_node_or_null("../Player")
	if player and player.has_method("check_nearby_objects"):
		player.check_nearby_objects()
		player_near_interactable = player.near_interactable


func _on_phase_changed(phase: String) -> void:
	print("UI: Фаза изменена на ", phase)
	
	match phase:
		"morning":
			_show_morning_ui()
		"path":
			_show_path_ui()
		"scene":
			pass
		"evening":
			_show_evening_ui()
		"night":
			_show_night_ui()


func _show_morning_ui() -> void:
	hide_all_panels()


func _show_path_ui() -> void:
	hide_all_panels()


func _show_evening_ui() -> void:
	hide_all_panels()


func _show_night_ui() -> void:
	hide_all_panels()


func _on_event_loaded(event_data: Dictionary) -> void:
	current_event = event_data
	hide_all_panels()
	
	event_text.text = format_event_text(event_data)
	event_panel.show()
	
	# Блокируем движение игрока во время события
	var player = get_node_or_null("../Player")
	if player:
		player.set_process(false)


func format_event_text(event_data: Dictionary) -> String:
	var base_text: String = event_data.get("text", "")
	return base_text


func _on_choices_presented(choices: Array) -> void:
	_clear_children(choices_container)
	
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button = Button.new()
		button.text = choice.get("text", "Выбор " + str(i + 1))
		button.custom_minimum_size = Vector2(300, 50)
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		choices_container.add_child(button)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_choice_button_pressed(index: int) -> void:
	choice_made.emit(index)
	
	# Добавляем выбор в debug лог
	var choice_text = current_event.get("choices", [])[index].get("text", "Неизвестный выбор")
	add_debug_log("ВЫБОР: " + choice_text)
	
	EventManager.make_choice(index)


func _on_event_completed(result: Dictionary) -> void:
	# Разблокируем движение игрока
	var player = get_node_or_null("../Player")
	if player:
		player.set_process(true)
	
	hide_all_panels()
	GameManager.on_event_completed(result)
	
	# Сбрасываем счетчик расстояния у игрока
	if player and player.has_method("reset_event_counter"):
		player.reset_event_counter()


func check_day_completion() -> void:
	day_completed.emit()


func _on_state_changed(new_state: int) -> void:
	var state_text: String = "Состояние: "
	match new_state:
		-2: state_text += "Критическое"
		-1: state_text += "Плохое"
		0: state_text += "Нейтральное"
		1: state_text += "Хорошее"
		2: state_text += "Отличное"
	
	state_label.text = state_text


func _on_day_started(day: int) -> void:
	day_label.text = "День " + str(day)
	update_archetype_display()
	add_debug_log("=== ДЕНЬ " + str(day) + " ===")


func update_archetype_display() -> void:
	var archetype: String = GameState.get_dominant_archetype()
	archetype_label.text = "Архетип: " + archetype.capitalize()


func _on_start_button_pressed() -> void:
	var start_button = get_node_or_null("StartButton")
	if start_button:
		start_button.hide()
	game_started = true
	show_ui = true
	toggle_ui_visibility(true)
	GameManager.start_new_game()
	add_debug_log("ИГРА НАЧАТА")


func add_debug_log(message: String) -> void:
	debug_log.append(message)
	update_debug_display()


func update_debug_display() -> void:
	if debug_label:
		var log_text = "DEBUG LOG:\n"
		# Показываем последние 15 записей
		var start_index = max(0, debug_log.size() - 15)
		for i in range(start_index, debug_log.size()):
			log_text += debug_log[i] + "\n"
		debug_label.text = log_text
