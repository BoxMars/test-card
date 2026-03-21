class_name CardView
extends Control

signal card_pressed(card_id: String, card_text: String)

var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _selected_hover_style: StyleBoxFlat
var _card_id := ""
var _card_text := ""
var _is_selected := false
var _is_disabled := false
var _is_hovered := false
var _lift_root: PanelContainer
var _content_root: MarginContainer

const SELECTED_LIFT := -12.0


func setup(card_id: String, card_text: String) -> void:
	_card_id = card_id
	_card_text = card_text
	custom_minimum_size = _get_card_size_for_mode(card_text)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = custom_minimum_size / 2.0

	var card_color: Color = _get_card_color(card_text)
	_normal_style = _build_panel_style(card_color, false)
	_hover_style = _build_panel_style(card_color, true)
	_selected_style = _build_selected_panel_style(card_color, false)
	_selected_hover_style = _build_selected_panel_style(card_color, true)

	_lift_root = PanelContainer.new()
	_lift_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lift_root.add_theme_stylebox_override("panel", _normal_style)
	add_child(_lift_root)
	_sync_lift_root_frame()
	resized.connect(_sync_lift_root_frame)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 5)
	_lift_root.add_child(margin)
	_content_root = margin

	var settings: Node = _get_user_settings()
	if settings != null and String(settings.get_render_mode()) == "atlas":
		_build_atlas_face(card_text)
	else:
		_build_programmatic_face(card_text, card_color)


func _build_programmatic_face(card_text: String, card_color: Color) -> void:
	if _content_root == null:
		return

	var content: VBoxContainer = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	_content_root.add_child(content)

	var display_rank: String = _get_display_rank(card_text)
	var display_suit: String = _get_display_suit(card_text)
	var is_joker: bool = _is_joker_card(card_text)

	var top_corner: VBoxContainer = VBoxContainer.new()
	top_corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_corner.custom_minimum_size = Vector2(24, 28)
	top_corner.add_theme_constant_override("separation", 0)
	content.add_child(top_corner)

	var top_suit_label: Label = Label.new()
	top_suit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_suit_label.text = display_suit
	top_suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_suit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_suit_label.custom_minimum_size = Vector2(24, 12)
	top_suit_label.add_theme_font_size_override("font_size", 11)
	top_suit_label.modulate = card_color
	top_corner.add_child(top_suit_label)

	var top_label: Label = Label.new()
	top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_label.text = display_rank
	top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_label.custom_minimum_size = Vector2(24, 14)
	top_label.add_theme_font_size_override("font_size", 13 if not is_joker else 10)
	top_label.modulate = card_color
	top_corner.add_child(top_label)

	var spacer: Control = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var bottom_spacer: Control = Control.new()
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom_spacer)

	var bottom_corner: VBoxContainer = VBoxContainer.new()
	bottom_corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_corner.custom_minimum_size = Vector2(24, 28)
	bottom_corner.add_theme_constant_override("separation", 0)
	content.add_child(bottom_corner)

	var bottom_label: Label = Label.new()
	bottom_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_label.text = display_rank
	bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_label.custom_minimum_size = Vector2(24, 14)
	bottom_label.add_theme_font_size_override("font_size", 13 if not is_joker else 10)
	bottom_label.modulate = card_color
	bottom_corner.add_child(bottom_label)

	var bottom_suit_label: Label = Label.new()
	bottom_suit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_suit_label.text = display_suit
	bottom_suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_suit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_suit_label.custom_minimum_size = Vector2(24, 12)
	bottom_suit_label.add_theme_font_size_override("font_size", 11)
	bottom_suit_label.modulate = card_color
	bottom_corner.add_child(bottom_suit_label)


func _build_atlas_face(card_text: String) -> void:
	if _content_root == null:
		return

	_content_root.add_theme_constant_override("margin_left", 0)
	_content_root.add_theme_constant_override("margin_top", 0)
	_content_root.add_theme_constant_override("margin_right", 0)
	_content_root.add_theme_constant_override("margin_bottom", 0)

	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture = _get_atlas_texture(card_text)
	_content_root.add_child(texture_rect)

	if card_text == "皇帝牌" or card_text == "♥4":
		_add_rainbow_special_overlay()


func _build_panel_style(card_color: Color, hovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.982, 0.973, 0.937)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.157, 0.192, 0.22)
	if hovered:
		style.shadow_color = Color(card_color.r, card_color.g, card_color.b, 0.28)
		style.shadow_size = 10
		style.border_color = card_color.lightened(0.2)
		style.bg_color = Color(1, 0.992, 0.958)
	else:
		style.shadow_color = Color(0, 0, 0, 0.18)
		style.shadow_size = 4
	return style


func _build_selected_panel_style(card_color: Color, hovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if hovered:
		style.bg_color = Color(1, 0.983, 0.925)
	else:
		style.bg_color = Color(0.995, 0.976, 0.89)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.894, 0.678, 0.243)
	if hovered:
		style.shadow_color = Color(0.894, 0.678, 0.243, 0.34)
		style.shadow_size = 12
	else:
		style.shadow_color = Color(0.894, 0.678, 0.243, 0.24)
		style.shadow_size = 8
	return style


func _add_rainbow_special_overlay() -> void:
	if _content_root == null:
		return

	var rainbow_overlay := TextureRect.new()
	rainbow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rainbow_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rainbow_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rainbow_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	rainbow_overlay.modulate = Color(1, 1, 1, 0.82)

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1.0, 0.16, 0.24, 0.65),
		Color(1.0, 0.56, 0.16, 0.56),
		Color(1.0, 0.9, 0.18, 0.54),
		Color(0.18, 0.88, 0.38, 0.52),
		Color(0.18, 0.6, 1.0, 0.56),
		Color(0.62, 0.24, 1.0, 0.62)
	])

	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(1, 1)
	rainbow_overlay.texture = gradient_texture
	_content_root.add_child(rainbow_overlay)

	var glow_overlay := TextureRect.new()
	glow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	glow_overlay.modulate = Color(1, 1, 1, 0.46)
	glow_overlay.texture = gradient_texture
	glow_overlay.material = CanvasItemMaterial.new()
	glow_overlay.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_content_root.add_child(glow_overlay)


func set_selected(selected: bool, animated: bool = true) -> void:
	if _is_selected == selected:
		return
	_is_selected = selected
	_refresh_style()
	_refresh_lift(animated)


func set_disabled(disabled: bool, dimmed: bool = false) -> void:
	_is_disabled = disabled
	if disabled:
		if dimmed:
			modulate = Color(1, 1, 1, 0.42)
		else:
			modulate = Color(1, 1, 1, 1)
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		modulate = Color(1, 1, 1, 1)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_refresh_style()


func _refresh_style() -> void:
	if _lift_root == null:
		return
	if _is_selected:
		_lift_root.add_theme_stylebox_override("panel", _selected_style)
	else:
		_lift_root.add_theme_stylebox_override("panel", _normal_style)


func _refresh_lift(animated: bool = true) -> void:
	var target_y: float = 0.0
	if _is_selected:
		target_y = SELECTED_LIFT

	if not animated:
		if _lift_root != null:
			_lift_root.position.y = target_y
			_lift_root.size = size
		return

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	if _lift_root != null:
		_lift_root.size = size
		tween.tween_property(_lift_root, "position:y", target_y, 0.12)


func _on_mouse_entered() -> void:
	if _is_disabled:
		return
	_is_hovered = true
	if _is_selected:
		_lift_root.add_theme_stylebox_override("panel", _selected_hover_style)
	else:
		_lift_root.add_theme_stylebox_override("panel", _hover_style)


func _on_mouse_exited() -> void:
	if _is_disabled:
		return
	_is_hovered = false
	_refresh_style()


func _gui_input(event: InputEvent) -> void:
	if _is_disabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			card_pressed.emit(_card_id, _card_text)
			accept_event()


func _get_card_color(card_text: String) -> Color:
	if "♥" in card_text or "♦" in card_text or "大王" in card_text or "皇帝" in card_text:
		return Color(0.722, 0.176, 0.196)
	return Color(0.102, 0.118, 0.149)


func _get_atlas_texture(card_text: String) -> Texture2D:
	var settings: Node = _get_user_settings()
	if settings == null:
		return null
	if card_text == "大王":
		return settings.get_joker_texture(false)
	if card_text == "小王":
		return settings.get_joker_invert_texture()
	if card_text == "皇帝牌":
		return settings.get_joker_texture(false)
	return settings.get_standard_card_texture(card_text)


func _get_card_size_for_mode(card_text: String) -> Vector2:
	var default_size: Vector2 = Vector2(66, 96)
	var settings: Node = _get_user_settings()
	if settings == null or String(settings.get_render_mode()) != "atlas":
		return default_size

	var texture: Texture2D = _get_atlas_texture(card_text)
	if texture == null:
		return default_size

	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return default_size

	var target_height: float = 104.0
	var target_width: float = round(target_height * texture_size.x / texture_size.y)
	return Vector2(target_width, target_height)


func get_card_id() -> String:
	return _card_id


func _sync_lift_root_frame() -> void:
	if _lift_root == null:
		return
	_lift_root.position.x = 0
	_lift_root.size = size
	if _is_selected:
		_lift_root.position.y = SELECTED_LIFT
	else:
		_lift_root.position.y = 0


func _get_display_rank(card_text: String) -> String:
	if card_text == "♥4":
		return "侍卫"
	if card_text == "皇帝牌":
		return "皇帝牌"
	if card_text == "大王" or card_text == "小王" or card_text == "皇帝牌":
		return "JOKER"
	if card_text.length() >= 2:
		return card_text.substr(1)
	return card_text


func _get_display_suit(card_text: String) -> String:
	if card_text == "♥4":
		return "♥"
	if card_text == "大王":
		return "▲"
	if card_text == "小王":
		return "★"
	if card_text == "皇帝牌":
		return "♛"
	if card_text.length() >= 1:
		return card_text.left(1)
	return ""


func _is_joker_card(card_text: String) -> bool:
	return card_text == "大王" or card_text == "小王" or card_text == "皇帝牌"


func _get_user_settings() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("UserSettings")
	return null
