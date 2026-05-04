# scripts/player.gd
extends CharacterBody2D

@export var speed := 200.0
@export var gravity := 900.0
@export var jump_force := -400.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	move_and_slide()
