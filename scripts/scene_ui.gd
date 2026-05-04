# SceneUI.gd
extends Control
@onready var btn1 = $Panel/VBoxContainer/Button1
@onready var btn2 = $Panel/VBoxContainer/Button2
@onready var btn3 = $Panel/VBoxContainer/Button3
signal choice_selected(choice_id)

func _ready():
	visible = false
	
	# Настройка размеров панели и кнопок
	$Panel.size = Vector2(200, 160)
	
	btn1.custom_minimum_size = Vector2(200, 50)
	btn2.custom_minimum_size = Vector2(200, 50)
	btn3.custom_minimum_size = Vector2(200, 50)
	
	# Настройка отступов в контейнере
	$Panel/VBoxContainer.add_theme_constant_override("separation", 5)
	
	btn1.pressed.connect(_on_button1_pressed)
	btn2.pressed.connect(_on_button2_pressed)
	btn3.pressed.connect(_on_button3_pressed)
func show_scene(_scene_id):
	visible = true
	
	# пока просто текст
	btn1.text = "Ждать"
	btn2.text = "Смотреть"
	btn3.text = "Пустота"

func _on_button1_pressed():
	choice_selected.emit("wait")

func _on_button2_pressed():
	choice_selected.emit("observe")

func _on_button3_pressed():
	choice_selected.emit("void")
