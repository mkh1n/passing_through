extends Node

## Main - Точка входа в игру
## Инициализирует GameManager и подключает сигналы UI

func _ready() -> void:
	print("[Main] Game starting...")
	
	# Подключаем сигналы UI к GameManager
	var ui = $UI/UIController
	var game_manager = GameManager
	
	if ui and game_manager:
		ui.ui_ready.connect(_on_ui_ready)
		ui.choice_made.connect(_on_choice_made)
		ui.photo_selected.connect(_on_photo_selected)
		ui.menu_action.connect(_on_menu_action)
		
		game_manager.phase_changed.connect(ui.on_phase_changed)
		game_manager.day_started.connect(_on_day_started)
	
	print("[Main] Signals connected. Ready to play.")

func _on_ui_ready() -> void:
	print("[Main] UI is ready")

func _on_menu_action(action: String) -> void:
	match action:
		"start_new_game":
			GameManager.start_new_game()
		"load_game":
			GameManager.load_game(0)
		"quit":
			get_tree().quit()

func _on_day_started(day_number: int) -> void:
	print("[Main] Day %d started" % day_number)
	# Обновляем HUD
	var ui = $UI/UIController
	if ui:
		ui.update_hud()

func _on_choice_made(choice_index: int) -> void:
	print("[Main] Choice made: %d" % choice_index)
	# Завершаем событие через GameManager
	GameManager.on_event_completed("current_event", choice_index)

func _on_photo_selected(photo_index: int) -> void:
	print("[Main] Photo selected: %d" % photo_index)
	# Сохраняем фото в память
	if MemorySystem:
		MemorySystem.select_for_memory(photo_index)
	# Переходим к ночи
	GameManager.on_photo_selected(photo_index)
