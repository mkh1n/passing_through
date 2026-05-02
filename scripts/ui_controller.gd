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

var current_event: Dictionary = {}
var is_photo_phase: bool = false


func _ready() -> void:
	hide_all_panels()
	setup_signals()


## Настройка сигналов от систем
func setup_signals() -> void:
	EventManager.event_loaded.connect(_on_event_loaded)
	EventManager.choices_presented.connect(_on_choices_presented)
	EventManager.event_completed.connect(_on_event_completed)
	GameState.state_changed.connect(_on_state_changed)
	GameState.day_started.connect(_on_day_started)
	MemorySystem.daily_summary_ready.connect(_on_daily_summary_ready)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("photo_trigger"):
		if is_photo_phase and not photo_panel.visible:
			show_photo_selection()
	
	if event.is_action_pressed("interact") and event_panel.visible:
		# Можно добавить пропуск события
		pass


## Скрытие всех панелей
func hide_all_panels() -> void:
	event_panel.hide()
	photo_panel.hide()


## Отображение события
func _on_event_loaded(event_data: Dictionary) -> void:
	current_event = event_data
	hide_all_panels()
	
	event_text.text = format_event_text(event_data)
	event_panel.show()


## Форматирование текста события с учётом архетипа
func format_event_text(event_data: Dictionary) -> String:
	var base_text := event_data.get("text", "")
	var archetype := GameState.get_dominant_archetype()
	var lens := GameState.current_lens
	
	# Применение модификаторов текста в зависимости от архетипа и линзы
	var modified_text := base_text
	
	# Здесь можно добавить логику замены ключевых слов
	# Например: {emotion} -> разное описание для разных архетипов
	
	return modified_text


## Отображение выборов
func _on_choices_presented(choices: Array[Dictionary]) -> void:
	_clear_children(choices_container)
	
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = choice.get("text", "Выбор " + str(i + 1))
		button.custom_minimum_size = Vector2(300, 50)
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		choices_container.add_child(button)


## Утилиты для очистки контейнеров
func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_choice_button_pressed(index: int) -> void:
	choice_made.emit(index)
	EventManager.make_choice(index)


## Завершение события
func _on_event_completed(result: Dictionary) -> void:
	# Проверка на наличие фото опций
	if result.photo_options and result.photo_options.size() > 0:
		is_photo_phase = true
		show_photo_selection()
	else:
		hide_all_panels()


## Отображение панели выбора фото
func show_photo_selection() -> void:
	hide_all_panels()
	photo_panel.show()
	_clear_children(photo_container)
	
	var photos := GameState.daily_photos
	if photos.is_empty():
		# Генерация дефолтных вариантов
		photos = MemorySystem.generate_photo_options(current_event, GameState.current_lens)
	
	for i in range(photos.size()):
		var photo: Dictionary = photos[i]
		var button := Button.new()
		button.text = photo.get("description", "Фото " + str(i + 1))
		button.custom_minimum_size = Vector2(250, 150)
		button.pressed.connect(_on_photo_button_pressed.bind(i))
		photo_container.add_child(button)


func _on_photo_button_pressed(index: int) -> void:
	photo_selected.emit(index)
	MemorySystem.select_daily_memory(index)
	photo_panel.hide()
	is_photo_phase = false
	
	# Проверка на конец дня
	check_day_completion()


## Проверка завершения дня
func check_day_completion() -> void:
	# Логика завершения дня (например, после 3 событий)
	# Пока просто эмитим сигнал
	day_completed.emit()


## Обновление отображения состояния
func _on_state_changed(new_state: int) -> void:
	var state_text := "Состояние: "
	match new_state:
		-2: state_text += "Критическое"
		-1: state_text += "Плохое"
		0: state_text += "Нейтральное"
		1: state_text += "Хорошее"
		2: state_text += "Отличное"
	
	state_label.text = state_text


## Обновление номера дня
func _on_day_started(day: int) -> void:
	day_label.text = "День " + str(day)
	update_archetype_display()


## Обновление отображения архетипа
func update_archetype_display() -> void:
	var archetype := GameState.get_dominant_archetype()
	archetype_label.text = "Архетип: " + archetype.capitalize()


## Обработка ежедневного итога
func _on_daily_summary_ready(photos: Array[Dictionary], selected_index: int) -> void:
	# Можно показать краткий итог дня
	print("День завершён. Выбрано фото: ", photos[selected_index].get("description", ""))
