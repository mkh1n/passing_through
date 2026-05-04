# scripts/photo_system.gd
extends Node

var photos := []

func save(scene_id, choice_id):
	photos.append({
		"scene": scene_id,
		"choice": choice_id
	})

	print("📸", photos)
