# scripts/scene_trigger.gd
extends Area2D

@export var scene_id := "bus_stop"

signal triggered(scene_id)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		triggered.emit(scene_id)
