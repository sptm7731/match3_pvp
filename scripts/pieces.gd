extends Node2D

@export var color:String;

var matched = false;

func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self,"position",target, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func dim():
	var sprite = get_node("sprite2D");
	sprite.modulate = Color(1,1,1,0.5);
	pass;
