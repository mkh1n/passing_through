extends CanvasLayer
## PauseMenu - Меню паузы с сохранением/загрузкой
## Вызывается по ESC, позволяет сохраниться, загрузиться, продолжить

signal game_resumed()
signal game_saved()
signal game_quit_to_menu()

var is_paused: bool = false

@onready var pause_panel: Panel = $PausePanel if has_node("PausePanel") else null
@onready var save_button: Button = $PausePanel/SaveButton if has_node("PausePanel/SaveButton") else null
@onready var resume_button: Button = $PausePanel/ResumeButton if has_node("PausePanel/ResumeButton") else null
@onready var quit_button: Button = $PausePanel/QuitButton if has_node("PausePanel/QuitButton") else null


func _ready() -> void:
	visible = false
	
	# Only connect signals if buttons exist
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Auto-create pause menu if missing
	if not pause_panel:
		_create_pause_menu()


func _create_pause_menu() -> void:
	"""Dynamically create pause menu if it doesn't exist in scene"""
	pause_panel = Panel.new()
	pause_panel.name = "PausePanel"
	pause_panel.visible = false
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.size = Vector2(400, 300)
	pause_panel.modulate = Color(0, 0, 0, 0.8)
	add_child(pause_panel)
	
	resume_button = Button.new()
	resume_button.name = "ResumeButton"
	resume_button.text = "Продолжить"
	resume_button.position = Vector2(150, 80)
	resume_button.size = Vector2(100, 40)
	pause_panel.add_child(resume_button)
	
	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "Сохранить"
	save_button.position = Vector2(150, 140)
	save_button.size = Vector2(100, 40)
	pause_panel.add_child(save_button)
	
	quit_button = Button.new()
	quit_button.name = "QuitButton"
	quit_button.text = "Выйти в меню"
	quit_button.position = Vector2(150, 200)
	quit_button.size = Vector2(100, 40)
	pause_panel.add_child(quit_button)
	
	# Connect signals
	save_button.pressed.connect(_on_save_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC
		toggle_pause()


func toggle_pause() -> void:
	is_paused = not is_paused
	visible = is_paused
	if pause_panel:
		pause_panel.visible = is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		print("Игра на паузе")
	else:
		print("Игра продолжена")
		game_resumed.emit()


func _on_save_pressed() -> void:
	# Assuming MemorySystem is a global autoload
	if has_node("/root/MemorySystem"):
		MemorySystem.save_game()
		print("Игра сохранена")
		game_saved.emit()
	else:
		print("MemorySystem not found!")


func _on_resume_pressed() -> void:
	if is_paused:
		toggle_pause()


func _on_quit_pressed() -> void:
	is_paused = false
	visible = false
	if pause_panel:
		pause_panel.visible = false
	get_tree().paused = false
	game_quit_to_menu.emit()
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/main.tscn")
