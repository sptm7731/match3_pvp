extends Node2D

@export var type:String

var matched = false;

func dim():
	var sprite = get_node("Sprite2D");
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(sprite, "modulate:a", 0.1, 0.5)
	tween.tween_property(sprite, "scale", sprite.scale * 0.1, 0.5)
	pass;

func not_possible():
	var sprite = get_node("Sprite2D")
	var original_pos = sprite.position
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "position:x", original_pos.x + 5, 0.05) # move right
	tween.tween_property(sprite, "position:x", original_pos.x - 5, 0.05) # move left
	tween.tween_property(sprite, "position:x", original_pos.x + 3, 0.05) # small right
	tween.tween_property(sprite, "position:x", original_pos.x - 3, 0.05) # small left
	tween.tween_property(sprite, "position:x", original_pos.x, 0.05)     # back to center
