extends CanvasLayer
## PauseMenu - Меню паузы с сохранением/загрузкой
## Вызывается по ESC, позволяет сохраниться, загрузиться, продолжить

signal game_resumed()
signal game_saved()
signal game_quit_to_menu()

var is_paused: bool = false

@onready var pause_panel: Panel = $PausePanel
@onready var save_button: Button = $PausePanel/SaveButton
@onready var resume_button: Button = $PausePanel/ResumeButton
@onready var quit_button: Button = $PausePanel/QuitButton


func _ready() -> void:
	visible = false
	save_button.pressed.connect(_on_save_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC
		toggle_pause()


func toggle_pause() -> void:
	is_paused = not is_paused
	visible = is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		print("Игра на паузе")
	else:
		print("Игра продолжена")
		game_resumed.emit()


func _on_save_pressed() -> void:
	MemorySystem.save_game()
	print("Игра сохранена")
	game_saved.emit()
	# Можно показать уведомление о сохранении


func _on_resume_pressed() -> void:
	if is_paused:
		toggle_pause()


func _on_quit_pressed() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
	game_quit_to_menu.emit()
	# Возврат в главное меню или выход
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func show_pause_menu() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true


func hide_pause_menu() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
