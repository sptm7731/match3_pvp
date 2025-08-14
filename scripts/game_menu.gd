extends Control

func _ready():
	$MainMenuPanel.slide_in()
	$Settings_panel.slide_out()


func _on_main_menu_panel_settings_pressed():
	$MainMenuPanel.slide_out()
	$Settings_panel.slide_in()



func _on_settings_panel_back_button():
	$MainMenuPanel.slide_in()
	$Settings_panel.slide_out()


func _on_main_menu_panel_play_pressed():
	get_tree().change_scene_to_file("res://game_window.tscn")
	pass # Replace with function body.
