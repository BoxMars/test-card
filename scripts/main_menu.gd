extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const SETTINGS_SCENE := "res://scenes/settings.tscn"
const UI_SKIN := preload("res://scripts/ui_skin.gd")
const STAGE_SHADER := preload("res://shaders/table_stage.gdshader")
const DEFAULT_PORT := 7000

@onready var name_input: LineEdit = %NameInput
@onready var address_input: LineEdit = %AddressInput
@onready var port_input: LineEdit = %PortInput
@onready var network_status: Label = %NetworkStatus
@onready var start_button: Button = $Center/Panel/VBox/StartButton
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var settings_button: Button = $Center/Panel/VBox/SettingsButton
@onready var quit_button: Button = $Center/Panel/VBox/QuitButton


func _ready() -> void:
	_apply_ui_skin()
	_apply_background_shader()
	_load_user_name()
	_connect_network_manager()
	start_button.pressed.connect(_on_start_button_pressed)
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	name_input.focus_exited.connect(_commit_user_name)
	port_input.text_submitted.connect(_on_port_submitted)


func _apply_ui_skin() -> void:
	UI_SKIN.apply_panel($Center/Panel, "warm")
	UI_SKIN.apply_panel($Center/Panel/VBox/NameDock, "black")
	UI_SKIN.apply_panel($Center/Panel/VBox/NetworkDock, "black")
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
	UI_SKIN.apply_label($Center/Panel/VBox/Title, "title")
	UI_SKIN.apply_label($Center/Panel/VBox/Subtitle, "muted")
	UI_SKIN.apply_label($Center/Panel/VBox/NameDock/NameDockRow/NameLabel, "muted")
	UI_SKIN.apply_label($Center/Panel/VBox/NetworkDock/NetworkVBox/NetworkLabel, "muted")
	UI_SKIN.apply_label(network_status, "muted")
	UI_SKIN.apply_line_edit(name_input, "warm")
	UI_SKIN.apply_line_edit(address_input, "warm")
	UI_SKIN.apply_line_edit(port_input, "warm")
	UI_SKIN.apply_button(start_button, "primary")
	UI_SKIN.apply_button(host_button, "secondary")
	UI_SKIN.apply_button(join_button, "secondary")
	UI_SKIN.apply_button(settings_button, "secondary")
	UI_SKIN.apply_button(quit_button, "danger")


func _apply_background_shader() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = STAGE_SHADER
	shader_material.set_shader_parameter("colour_1", Color(0.05, 0.08, 0.09, 1.0))
	shader_material.set_shader_parameter("colour_2", Color(0.07, 0.26, 0.23, 1.0))
	shader_material.set_shader_parameter("colour_3", Color(0.91, 0.67, 0.31, 1.0))
	shader_material.set_shader_parameter("contrast", 1.28)
	shader_material.set_shader_parameter("spin_amount", 0.14)
	$Background.material = shader_material
	$StageGlow.color = Color(0.10, 0.31, 0.27, 0.46)


func _on_start_button_pressed() -> void:
	_commit_user_name()
	var network_manager := get_node_or_null("/root/NetworkManager")
	if network_manager != null:
		network_manager.leave_session()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_host_button_pressed() -> void:
	_commit_user_name()
	var network_manager := get_node_or_null("/root/NetworkManager")
	if network_manager == null:
		return
	var port := _parse_port()
	var err: int = network_manager.host_game(name_input.text, port)
	if err != OK:
		network_status.text = "创建房间失败，错误码 %d。" % err
		return
	network_status.text = "房间已创建，本机端口 %d。" % port


func _on_join_button_pressed() -> void:
	_commit_user_name()
	var network_manager := get_node_or_null("/root/NetworkManager")
	if network_manager == null:
		return
	var address := address_input.text.strip_edges()
	if address == "":
		address = "127.0.0.1"
		address_input.text = address
	var port := _parse_port()
	var err: int = network_manager.join_game(name_input.text, address, port)
	if err != OK:
		network_status.text = "加入房间失败，错误码 %d。" % err
		return
	network_status.text = "正在连接 %s:%d ..." % [address, port]


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
	address_input.text = "127.0.0.1"
	port_input.text = str(DEFAULT_PORT)


func _on_name_submitted(_text: String) -> void:
	_commit_user_name()


func _commit_user_name() -> void:
	var settings := get_node_or_null("/root/UserSettings")
	if settings == null:
		return
	settings.set_user_name(name_input.text)
	name_input.text = String(settings.get_user_name())


func _on_port_submitted(_text: String) -> void:
	port_input.text = str(_parse_port())


func _parse_port() -> int:
	var port := int(port_input.text)
	if port <= 0 or port > 65535:
		port = DEFAULT_PORT
		port_input.text = str(port)
	return port


func _connect_network_manager() -> void:
	var network_manager := get_node_or_null("/root/NetworkManager")
	if network_manager == null:
		return
	if not network_manager.connection_failed.is_connected(_on_network_connection_failed):
		network_manager.connection_failed.connect(_on_network_connection_failed)
	if not network_manager.connection_ready.is_connected(_on_network_connection_ready):
		network_manager.connection_ready.connect(_on_network_connection_ready)
	if not network_manager.disconnected.is_connected(_on_network_disconnected):
		network_manager.disconnected.connect(_on_network_disconnected)


func _on_network_connection_ready() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_network_connection_failed(message: String) -> void:
	network_status.text = message


func _on_network_disconnected(message: String) -> void:
	network_status.text = message
