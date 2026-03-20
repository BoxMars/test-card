extends Control


func _ready() -> void:
	$CenterBox/Panel/VBox/StartButton.pressed.connect(_on_start_button_pressed)
	$CenterBox/Panel/VBox/QuitButton.pressed.connect(_on_quit_button_pressed)


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
