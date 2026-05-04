# scripts/scene_manager.gd
extends Node

var current_scene := ""
var active := false

signal started(scene_id)
signal ended()

func start(scene_id):
	if active:
		return

	active = true
	current_scene = scene_id
	
	started.emit(scene_id)

func end():
	active = false
	ended.emit()
