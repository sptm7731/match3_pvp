extends Node2D

@export var player_class:String;

func damaged():
	var sprite = get_node("Sprite2D")
	var original_pos = sprite.position
	var original_color = sprite.modulate
	
	var tween = get_tree().create_tween()
	
	tween.tween_property(sprite, "modulate", Color(1, 0, 0), 0.05) # Red
	tween.tween_property(sprite, "position:x", original_pos.x + 5, 0.05) # Move right
	tween.tween_property(sprite, "position:x", original_pos.x - 5, 0.05) # Move left
	tween.tween_property(sprite, "position:x", original_pos.x + 3, 0.05) # Small right
	tween.tween_property(sprite, "position:x", original_pos.x - 3, 0.05) # Small left
	
	tween.tween_property(sprite, "position:x", original_pos.x, 0.05) # Back to center
	tween.tween_property(sprite, "modulate", original_color, 0.05)   # Back to normal color
