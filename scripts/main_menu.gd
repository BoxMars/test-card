extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const SETTINGS_SCENE := "res://scenes/settings.tscn"
const UI_SKIN := preload("res://scripts/ui_skin.gd")


func _ready() -> void:
	_apply_ui_skin()
	$CenterBox/Panel/VBox/StartButton.pressed.connect(_on_start_button_pressed)
	$CenterBox/Panel/VBox/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$CenterBox/Panel/VBox/QuitButton.pressed.connect(_on_quit_button_pressed)


func _apply_ui_skin() -> void:
	UI_SKIN.apply_panel($CenterBox/Panel, "warm")
	UI_SKIN.apply_label($CenterBox/Panel/VBox/Title, "title")
	UI_SKIN.apply_label($CenterBox/Panel/VBox/Subtitle, "muted")
	UI_SKIN.apply_button($CenterBox/Panel/VBox/StartButton, "primary")
	UI_SKIN.apply_button($CenterBox/Panel/VBox/SettingsButton, "secondary")
	UI_SKIN.apply_button($CenterBox/Panel/VBox/QuitButton, "danger")


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
