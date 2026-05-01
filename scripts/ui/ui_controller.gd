## UIController - Управление интерфейсом
## Обрабатывает все UI элементы: HUD, диалоги, фото-выбор, меню
## Связывает GameState с визуальным представлением

extends CanvasLayer

# ==================== СИГНАЛЫ ====================
signal ui_ready
signal choice_made(choice_index: int)
signal photo_selected(index: int)
signal menu_action(action: String)

# ==================== ЭКСПОРТИРУЕМЫЕ ПЕРЕМЕННЫЕ ====================
# HUD элементы
@export var hud_panel: Panel
@export var state_label: Label
@export var day_label: Label
@export var track_labels: Dictionary  # {"action": Label, "observe": Label, "connect": Label}

# Диалоговое окно события
@export var event_panel: Panel
@export var event_title_label: Label
@export var event_description_label: Label
@export var choice_buttons_container: VBoxContainer
@export var choice_button_scene: PackedScene

# Фото-выбор (вечер)
@export var photo_selection_panel: Panel
@export var photo_slots_container: HBoxContainer
@export var photo_slot_scene: PackedScene

# Прогресс-бар дня
@export var day_progress_bar: ProgressBar

# Главное меню
@export var menu_panel: Panel
@export var start_button: Button
@export var load_button: Button
@export var quit_button: Button

# ==================== ПЕРЕМЕННЫЕ ====================
var current_event_data: Dictionary = {}
var is_ui_active: bool = false

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	print("[UIController] Initialized")
	
	# Подключаем сигналы кнопок меню
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Скрываем панели изначально
	hide_all_panels()
	show_menu()
	
	ui_ready.emit()

# ==================== УПРАВЛЕНИЕ ПАНЕЛЯМИ ====================
## Скрывает все панели
func hide_all_panels() -> void:
	for panel in [hud_panel, event_panel, photo_selection_panel, menu_panel]:
		if panel:
			panel.visible = false

## Показывает главную панель меню
func show_menu() -> void:
	hide_all_panels()
	if menu_panel:
		menu_panel.visible = true

## Показывает HUD
func show_hud() -> void:
	if hud_panel:
		hud_panel.visible = true
	update_hud()

## Скрывает HUD
func hide_hud() -> void:
	if hud_panel:
		hud_panel.visible = false

# ==================== HUD ====================
## Обновляет HUD данными из GameState
func update_hud() -> void:
	if not GameState:
		return
	
	# День
	if day_label:
		day_label.text = "День %d / 15" % GameState.current_day
	
	# Состояние
	if state_label:
		var state_text: = ""
		match GameState.player_state:
			-2: state_text = "😞 Глубоко"
			-1: state_text = "😟 Плохо"
			0: state_text = "😐 Нормально"
			1: state_text = "😊 Хорошо"
			2: state_text = "😄 Отлично"
		state_label.text = state_text
	
	# Треки
	for track in track_labels:
		if track_labels[track] and GameState.tracks.has(track):
			track_labels[track].text = "%s: %d" % [track.to_upper(), GameState.tracks[track]]

# ==================== СОБЫТИЯ ====================
## Показывает событие с выборами
func show_event(event_data: Dictionary) -> void:
	hide_all_panels()
	current_event_data = event_data
	
	if event_panel:
		event_panel.visible = true
	
	# Заголовок
	if event_title_label:
		event_title_label.text = event_data.get("title", "Событие")
	
	# Описание
	if event_description_label:
		event_description_label.text = event_data.get("description", "...")
	
	# Кнопки выборов
	clear_choice_buttons()
	
	var choices: = event_data.get("choices", [])
	for i in range(choices.size()):
		var choice: = choices[i]
		var button: = create_choice_button(choice, i)
		if choice_buttons_container:
			choice_buttons_container.add_child(button)

## Создаёт кнопку выбора
func create_choice_button(choice: Dictionary, index: int) -> Button:
	var button: = Button.new()
	button.text = choice.get("text", "Выбор %d" % (index + 1))
	button.pressed.connect(_on_choice_button_pressed.bind(index))
	
	# Если выбор недоступен из-за состояния
	if choice.has("required_state"):
		if GameState and GameState.player_state < choice["required_state"]:
			button.disabled = true
			button.text += " (недоступно)"
	
	return button

## Очищает кнопки выборов
func clear_choice_buttons() -> void:
	if choice_buttons_container:
		for child in choice_buttons_container.get_children():
			child.queue_free()

## Обработчик нажатия кнопки выбора
func _on_choice_button_pressed(index: int) -> void:
	print("[UIController] Choice made: %d" % index)
	choice_made.emit(index)
	hide_event()

## Скрывает событие
func hide_event() -> void:
	if event_panel:
		event_panel.visible = false

# ==================== ФОТО-ВЫБОР ====================
## Показывает панель выбора фото
func show_photo_selection(photos: Array) -> void:
	hide_all_panels()
	
	if photo_selection_panel:
		photo_selection_panel.visible = true
	
	# Создаём слоты для фото
	clear_photo_slots()
	
	for i in range(photos.size()):
		var photo: = photos[i]
		var slot: = create_photo_slot(photo, i)
		if photo_slots_container:
			photo_slots_container.add_child(slot)

## Создаёт слот для фото
func create_photo_slot(photo: Dictionary, index: int) -> TextureButton:
	var button: = TextureButton.new()
	
	# Здесь должна быть логика загрузки текстуры фото
	# Для плейсхолдера используем цвет
	var placeholder: = ColorRect.new()
	placeholder.custom_minimum_size = Vector2(150, 150)
	placeholder.color = Color.from_string(photo.get("perception_type", "ENVIRONMENT"), Color.GRAY)
	button.add_child(placeholder)
	
	button.pressed.connect(_on_photo_slot_pressed.bind(index))
	
	# Добавляем текст описания
	var label: = Label.new()
	label.text = photo.get("flavor_text", "")[:30] + "..."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(150, 40)
	placeholder.add_child(label)
	label.position.y = 160
	
	return button

## Очищает слоты фото
func clear_photo_slots() -> void:
	if photo_slots_container:
		for child in photo_slots_container.get_children():
			child.queue_free()

## Обработчик выбора фото
func _on_photo_slot_pressed(index: int) -> void:
	print("[UIController] Photo selected: %d" % index)
	photo_selected.emit(index)
	hide_photo_selection()

## Скрывает выбор фото
func hide_photo_selection() -> void:
	if photo_selection_panel:
		photo_selection_panel.visible = false

# ==================== МЕНЮ ====================
func _on_start_button_pressed() -> void:
	menu_action.emit("start_new_game")

func _on_load_button_pressed() -> void:
	menu_action.emit("load_game")

func _on_quit_button_pressed() -> void:
	menu_action.emit("quit")

# ==================== ИНТЕГРАЦИЯ С GameManager ====================
## Вызывается при смене фазы игры
func on_phase_changed(phase: String) -> void:
	match phase:
		"MENU":
			show_menu()
			hide_hud()
		"MORNING", "TRAVEL":
			hide_all_panels()
			show_hud()
		"EVENT":
			show_hud()
		"EVENING":
			hide_hud()
			if MemorySystem:
				show_photo_selection(MemorySystem.daily_photos)
		"NIGHT":
			hide_all_panels()
		"FINAL":
			hide_all_panels()

# ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
## Показывает всплывающее уведомление
func show_notification(text: String, duration: float = 2.0) -> void:
	# Можно добавить Toast/Notification узел
	print("[UI] Notification: %s" % text)

## Обновляет прогресс дня
func update_day_progress(progress: float) -> void:
	if day_progress_bar:
		day_progress_bar.value = progress * 100
