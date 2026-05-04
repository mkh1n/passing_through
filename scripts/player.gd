extends CharacterBody2D

@export var speed := 200.0
@export var gravity := 900.0

@onready var anim = $AnimationPlayer
@onready var skeleton = $Skeleton

func _ready():
	add_to_group("player")
	# ДИАГНОСТИКА
	print("=== ДИАГНОСТИКА СКЕЛЕТА ===")
	print("AnimationPlayer: ", anim)
	print("Skeleton: ", skeleton)
	
	# Проверяем существование костей
	var bones = [
		"Body",
		"Body/UpperArmL",
		"Body/UpperArmL/LowerArmL",
		"Body/UpperArmR",
		"Body/UpperArmR/LowerArmR",
		"Body/UpperLegL",
		"Body/UpperLegL/LowerLegL",
		"Body/UpperLegR",
		"Body/UpperLegR/LowerLegR"
	]
	
	for bone_path in bones:
		if skeleton.has_node(bone_path):
			var bone = skeleton.get_node(bone_path)
			print("✓ ", bone_path, " | auto_calc: ", bone.auto_calculate_length_and_angle)
		else:
			print("✗ ", bone_path, " NOT FOUND!")
	
	print("\n=== ПРОВЕРКА АНИМАЦИЙ ===")
	print("Has 'idle': ", anim.has_animation("idle"))
	print("Has 'walk': ", anim.has_animation("walk"))
	
	# Пробуем проиграть
	anim.play("idle")
	print("Playing: ", anim.current_animation)
	print("Is playing: ", anim.is_playing())
	
	# Проверяем треки
	var anim_lib = anim.get_animation("idle")
	if anim_lib:
		print("Idle tracks count: ", anim_lib.get_track_count())
		for i in range(anim_lib.get_track_count()):
			var path = anim_lib.track_get_path(i)
			print("  Track ", i, ": ", path)

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta

	# Движение
	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed

	# Флип персонажа
	if dir != 0:
		skeleton.scale.x = sign(dir)

	# 👉 АНИМАЦИИ
	update_animation(dir)

	move_and_slide()
	


func update_animation(dir):

	# Ходьба
	if abs(dir) > 0.1:
		play_anim("walk", 1.2)
	else:
		play_anim("idle")


# Переименовал параметр, чтобы не конфликтовал с Node.name
func play_anim(anim_name: String, speed_scale := 1.0):
	if anim.current_animation != anim_name:
		anim.play(anim_name)
	
	anim.speed_scale = speed_scale
