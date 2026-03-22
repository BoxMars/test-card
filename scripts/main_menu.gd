extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const SETTINGS_SCENE := "res://scenes/settings.tscn"
const UI_SKIN := preload("res://scripts/ui_skin.gd")
const STAGE_SHADER := preload("res://shaders/balatro_stage.gdshader")

@onready var name_input: LineEdit = %NameInput


func _ready() -> void:
	_apply_ui_skin()
	_apply_background_shader()
	_load_user_name()
	$CenterBox/Panel/VBox/StartButton.pressed.connect(_on_start_button_pressed)
	$CenterBox/Panel/VBox/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$CenterBox/Panel/VBox/QuitButton.pressed.connect(_on_quit_button_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	name_input.focus_exited.connect(_commit_user_name)


func _apply_ui_skin() -> void:
	UI_SKIN.apply_panel($CenterBox/Panel, "warm")
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0)
	frame_style.border_color = Color(0.93, 0.83, 0.63, 0.18)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.corner_radius_top_left = 22
	frame_style.corner_radius_top_right = 22
	frame_style.corner_radius_bottom_left = 22
	frame_style.corner_radius_bottom_right = 22
	frame_style.content_margin_left = 24
	frame_style.content_margin_top = 24
	frame_style.content_margin_right = 24
	frame_style.content_margin_bottom = 24
	$Frame.add_theme_stylebox_override("panel", frame_style)
	UI_SKIN.apply_label($CenterBox/Panel/VBox/Title, "title")
	var subtitle := $CenterBox/Panel/VBox.get_node_or_null("Subtitle")
	if subtitle != null:
		UI_SKIN.apply_label(subtitle, "muted")
	UI_SKIN.apply_label($CenterBox/Panel/VBox/NameLabel, "muted")
	UI_SKIN.apply_line_edit(name_input, "warm")
	UI_SKIN.apply_button($CenterBox/Panel/VBox/StartButton, "primary")
	UI_SKIN.apply_button($CenterBox/Panel/VBox/SettingsButton, "secondary")
	UI_SKIN.apply_button($CenterBox/Panel/VBox/QuitButton, "danger")


func _apply_background_shader() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = STAGE_SHADER
	shader_material.set_shader_parameter("colour_1", Color(0.05, 0.08, 0.09, 1.0))
	shader_material.set_shader_parameter("colour_2", Color(0.07, 0.26, 0.23, 1.0))
	shader_material.set_shader_parameter("colour_3", Color(0.86, 0.47, 0.25, 1.0))
	shader_material.set_shader_parameter("contrast", 1.28)
	shader_material.set_shader_parameter("spin_amount", 0.14)
	$Background.material = shader_material
	$StageGlow.color = Color(0.09, 0.27, 0.24, 0.54)


func _on_start_button_pressed() -> void:
	_commit_user_name()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_quit_button_pressed() -> void:
	_commit_user_name()
	get_tree().quit()


func _load_user_name() -> void:
	var settings := get_node_or_null("/root/UserSettings")
	if settings == null:
		return
	name_input.text = String(settings.get_user_name())
	name_input.caret_column = name_input.text.length()


func _on_name_submitted(_text: String) -> void:
	_commit_user_name()


func _commit_user_name() -> void:
	var settings := get_node_or_null("/root/UserSettings")
	if settings == null:
		return
	settings.set_user_name(name_input.text)
	name_input.text = String(settings.get_user_name())
