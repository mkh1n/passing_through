extends CanvasLayer
## UIController - Управление интерфейсом
## Отображение событий, выборов, фото, мини-игр

signal choice_made(index: int)
signal photo_selected(index: int)
signal day_completed()
signal minigame_input_pressed()

@onready var event_panel: Panel = $EventPanel
@onready var event_text: RichTextLabel = $EventPanel/EventText
@onready var choices_container: VBoxContainer = $EventPanel/ChoicesContainer
@onready var photo_panel: Panel = $PhotoPanel
@onready var photo_container: HBoxContainer = $PhotoPanel/PhotoContainer
@onready var state_label: Label = $StateLabel
@onready var day_label: Label = $DayLabel
@onready var archetype_label: Label = $ArchetypeLabel

# Подсказка для фото
var photo_hint_label: Label

var current_event: Dictionary = {}
var is_photo_phase: bool = false
var game_started: bool = false
var show_ui: bool = false
var player_near_photo_object: bool = false


func _ready() -> void:
	hide_all_panels()
	setup_signals()
	create_photo_hint_label()
	
	if not has_node("StartButton"):
		create_start_button()
	
	toggle_ui_visibility(false)
	
	var start_button = get_node_or_null("StartButton")
	if start_button:
		start_button.show()


func create_photo_hint_label() -> void:
	var label = Label.new()
	label.name = "PhotoHintLabel"
	label.text = ""
	label.position = Vector2(1600, 950)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	photo_hint_label = label


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
	
	update_photo_hint()


func setup_signals() -> void:
	EventManager.event_loaded.connect(_on_event_loaded)
	EventManager.choices_presented.connect(_on_choices_presented)
	EventManager.event_completed.connect(_on_event_completed)
	GameState.state_changed.connect(_on_state_changed)
	GameState.day_started.connect(_on_day_started)
	MemorySystem.daily_summary_ready.connect(_on_daily_summary_ready)
	GameManager.day_phase_changed.connect(_on_phase_changed)
	
	var player = get_node_or_null("../Player")
	if player and player.has_signal("player_moved"):
		player.player_moved.connect(_on_player_moved)


func _input(event: InputEvent) -> void:
	if not game_started:
		return
	
	if event.is_action_pressed("photo_trigger"):
		if player_near_photo_object:
			_on_player_photo_requested()
	
	if event.is_action_pressed("interact") and event_panel.visible:
		pass


func hide_all_panels() -> void:
	event_panel.hide()
	photo_panel.hide()


func update_photo_hint() -> void:
	if photo_hint_label:
		if player_near_photo_object and game_started:
			photo_hint_label.text = "Сделать фото (Q)"
		else:
			photo_hint_label.text = ""


func _on_player_moved(direction: float) -> void:
	var player = get_node_or_null("../Player")
	if player and player.has_method("check_nearby_objects"):
		player.check_nearby_objects()
		player_near_photo_object = player.can_take_photo
		update_photo_hint()


func _on_player_photo_requested() -> void:
	print("Фото запрошено игроком")


func _on_phase_changed(phase: String) -> void:
	print("UI: Фаза изменена на ", phase)
	
	match phase:
		"morning":
			_show_morning_ui()
		"path":
			_show_path_ui()
		"scene":
			pass
		"photo":
			show_photo_selection()
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
	if GameState.daily_photos.size() > 0:
		show_photo_selection()
	else:
		await get_tree().create_timer(2.0).timeout
		if GameManager.current_phase == GameManager.GamePhase.EVENING:
			pass


func _show_night_ui() -> void:
	hide_all_panels()


func _on_event_loaded(event_data: Dictionary) -> void:
	current_event = event_data
	hide_all_panels()
	
	event_text.text = format_event_text(event_data)
	event_panel.show()


func format_event_text(event_data: Dictionary) -> String:
	var base_text: String = event_data.get("text", "")
	return base_text


func _on_choices_presented(choices: Array[Dictionary]) -> void:
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
	EventManager.make_choice(index)


func _on_event_completed(result: Dictionary) -> void:
	if result.photo_options and result.photo_options.size() > 0:
		is_photo_phase = true
		show_photo_selection()
	else:
		hide_all_panels()
		GameManager.on_event_completed(result)


func show_photo_selection() -> void:
	hide_all_panels()
	photo_panel.show()
	_clear_children(photo_container)
	
	var photos: Array[Dictionary] = GameState.daily_photos
	if photos.is_empty():
		photos = MemorySystem.generate_photo_options(current_event, GameState.current_lens)
	
	for i in range(photos.size()):
		var photo: Dictionary = photos[i]
		var button = Button.new()
		button.text = photo.get("description", "Фото " + str(i + 1))
		button.custom_minimum_size = Vector2(250, 150)
		button.pressed.connect(_on_photo_button_pressed.bind(i))
		photo_container.add_child(button)


func _on_photo_button_pressed(index: int) -> void:
	photo_selected.emit(index)
	MemorySystem.select_daily_memory(index)
	photo_panel.hide()
	is_photo_phase = false
	
	GameManager.on_photo_selected(index)


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


func update_archetype_display() -> void:
	var archetype: String = GameState.get_dominant_archetype()
	archetype_label.text = "Архетип: " + archetype.capitalize()


func _on_daily_summary_ready(photos: Array[Dictionary], selected_index: int) -> void:
	print("День завершён. Выбрано фото: ", photos[selected_index].get("description", ""))


func _on_start_button_pressed() -> void:
	var start_button = get_node_or_null("StartButton")
	if start_button:
		start_button.hide()
	game_started = true
	show_ui = true
	toggle_ui_visibility(true)
	GameManager.start_new_game()
