extends Node2D

@onready var player = $"../Player"
@onready var ground1 = $Ground1
@onready var ground2 = $Ground2

var width = 1920

func _ready():
	ground1.position = Vector2(0, 0)
	ground2.position = Vector2(width, 0)

func _process(delta):
	if player == null:
		return
	
	var player_x = player.global_position.x
	
	var g1_x = ground1.global_position.x
	var g2_x = ground2.global_position.x
	
	var leftmost = ground1 if g1_x < g2_x else ground2
	var rightmost = ground2 if leftmost == ground1 else ground1
	
	# 👉 ДВИЖЕНИЕ ВПРАВО
	if player_x - leftmost.global_position.x > width:
		leftmost.position.x = rightmost.position.x + width
		print("➡️ перенос вправо")
	
	# 👉 ДВИЖЕНИЕ ВЛЕВО
	elif rightmost.global_position.x - player_x > width:
		rightmost.position.x = leftmost.position.x - width
		print("⬅️ перенос влево")
