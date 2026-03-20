class_name CardView
extends PanelContainer

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


func setup(card_id: String, card_text: String) -> void:
	_card_id = card_id
	_card_text = card_text
	custom_minimum_size = Vector2(66, 96)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = custom_minimum_size / 2.0

	var card_color := _get_card_color(card_text)
	_normal_style = _build_panel_style(card_color, false)
	_hover_style = _build_panel_style(card_color, true)
	_selected_style = _build_selected_panel_style(card_color, false)
	_selected_hover_style = _build_selected_panel_style(card_color, true)
	add_theme_stylebox_override("panel", _normal_style)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 5)
	add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	var top_label := Label.new()
	top_label.text = card_text
	top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_label.add_theme_font_size_override("font_size", 13)
	top_label.modulate = card_color
	content.add_child(top_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var watermark := Label.new()
	watermark.text = _get_watermark_mark(card_text)
	watermark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	watermark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	watermark.add_theme_font_size_override("font_size", 28)
	watermark.modulate = Color(card_color.r, card_color.g, card_color.b, 0.13)
	content.add_child(watermark)

	var center_label := Label.new()
	center_label.text = _get_center_mark(card_text)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.add_theme_font_size_override("font_size", 15)
	center_label.modulate = card_color
	content.add_child(center_label)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom_spacer)

	var bottom_label := Label.new()
	bottom_label.text = card_text
	bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_label.add_theme_font_size_override("font_size", 13)
	bottom_label.modulate = card_color
	content.add_child(bottom_label)


func _build_panel_style(card_color: Color, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.982, 0.973, 0.937)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
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
	var style := StyleBoxFlat.new()
	if hovered:
		style.bg_color = Color(1, 0.983, 0.925)
	else:
		style.bg_color = Color(0.995, 0.976, 0.89)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
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


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_refresh_style()


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
	if _is_selected:
		add_theme_stylebox_override("panel", _selected_style)
	else:
		add_theme_stylebox_override("panel", _normal_style)


func _on_mouse_entered() -> void:
	if _is_disabled:
		return
	_is_hovered = true
	z_index = 20
	if _is_selected:
		add_theme_stylebox_override("panel", _selected_hover_style)
	else:
		add_theme_stylebox_override("panel", _hover_style)
	_animate_hover(Vector2(1.05, 1.05))


func _on_mouse_exited() -> void:
	if _is_disabled:
		return
	_is_hovered = false
	z_index = 0
	_refresh_style()
	_animate_hover(Vector2.ONE)


func _gui_input(event: InputEvent) -> void:
	if _is_disabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			card_pressed.emit(_card_id, _card_text)
			accept_event()


func _animate_hover(target_scale: Vector2) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.12)


func _get_card_color(card_text: String) -> Color:
	if "♥" in card_text or "♦" in card_text or "大王" in card_text or "皇帝" in card_text:
		return Color(0.722, 0.176, 0.196)
	return Color(0.102, 0.118, 0.149)


func _get_center_mark(card_text: String) -> String:
	if "皇帝" in card_text:
		return "帝"
	if "小王" in card_text:
		return "JOKER"
	if "大王" in card_text:
		return "JOKER"
	return card_text.substr(1)


func _get_watermark_mark(card_text: String) -> String:
	if "皇帝" in card_text:
		return "♛"
	if "♠" in card_text or "♥" in card_text or "♣" in card_text or "♦" in card_text:
		return card_text.left(1)
	return "★"


func get_card_id() -> String:
	return _card_id
