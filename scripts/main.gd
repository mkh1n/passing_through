# scripts/main.gd
extends Node2D

@onready var player = $Player
@onready var scene_manager = $SceneManager
@onready var photo_system = $PhotoSystem
@onready var ui = $SceneUI

func _ready():
	# подключаем триггер
	$Trigger.triggered.connect(_on_triggered)
	
	ui.choice_selected.connect(_on_choice)

func _on_triggered(scene_id):
	scene_manager.start(scene_id)
	ui.show_scene(scene_id)
	player.set_physics_process(false)

func _on_choice(choice_id):
	photo_system.save(scene_manager.current_scene, choice_id)

	scene_manager.end()
	ui.visible = false
	player.set_physics_process(true)
