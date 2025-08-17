extends "res://scripts/base_menu_panel.gd"


signal power_mode
signal normal_mode


func _on_button_1_pressed():
	emit_signal("power_mode")


func _on_button_2_pressed():
	emit_signal("normal_mode")
