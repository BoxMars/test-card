@tool
class_name CardView
extends Control

signal card_pressed(card_id: String, card_text: String)

const SELECTED_LIFT: float = -12.0
const CORNER_RADIUS: float = 8.0
const CARD_SHEET: Texture2D = preload("res://figures/card.png")
const JOKER_SHEET: Texture2D = preload("res://figures/jokers.png")
const CARD_COLUMNS: int = 13
const CARD_ROWS: int = 4
const JOKER_COLUMNS: int = 10
const JOKER_ROWS: int = 16
const CARD_RANK_ORDER := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const CARD_SUIT_ORDER := ["♥", "♣", "♦", "♠"]
const RAINBOW_OVERLAY_SHADER_BODY := """

uniform float corner_radius_px = 8.0;
uniform vec2 rect_size_px = vec2(74.0, 108.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	vec2 pos = UV * rect_size_px;
	vec2 size = rect_size_px;
	float radius = min(corner_radius_px, min(size.x, size.y) * 0.5);

	if (pos.x < radius && pos.y < radius) {
		if (distance(pos, vec2(radius, radius)) > radius) {
			discard;
		}
	} else if (pos.x > size.x - radius && pos.y < radius) {
		if (distance(pos, vec2(size.x - radius, radius)) > radius) {
			discard;
		}
	} else if (pos.x < radius && pos.y > size.y - radius) {
		if (distance(pos, vec2(radius, size.y - radius)) > radius) {
			discard;
		}
	} else if (pos.x > size.x - radius && pos.y > size.y - radius) {
		if (distance(pos, vec2(size.x - radius, size.y - radius)) > radius) {
			discard;
		}
	}

	COLOR = color;
}
"""

var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _selected_hover_style: StyleBoxFlat
var _card_id: String = ""
var _card_text: String = ""
var _is_selected: bool = false
var _is_disabled: bool = false
var _is_hovered: bool = false
var _is_marked_gain: bool = false
var _did_setup: bool = false

@export var preview_purchase_badge: bool = false:
	set(value):
		preview_purchase_badge = value
		if is_node_ready():
			_update_editor_preview_state()
		else:
			call_deferred("_update_editor_preview_state")
@export var preview_card_text: String = "♠A":
	set(value):
		preview_card_text = value
		if Engine.is_editor_hint() and is_node_ready() and not _did_setup:
			_apply_setup()
@export var preview_use_atlas: bool = true:
	set(value):
		preview_use_atlas = value
		if Engine.is_editor_hint() and is_node_ready() and not _did_setup:
			_apply_setup()

@onready var _lift_root: PanelContainer = %LiftRoot
@onready var _overlay_root: Control = %OverlayRoot
@onready var _content_root: MarginContainer = %ContentRoot
@onready var _programmatic_face: VBoxContainer = %ProgrammaticFace
@onready var _top_suit_label: Label = %TopSuitLabel
@onready var _top_label: Label = %TopRankLabel
@onready var _bottom_label: Label = %BottomRankLabel
@onready var _bottom_suit_label: Label = %BottomSuitLabel
@onready var _atlas_texture: TextureRect = %AtlasTexture
@onready var _rainbow_overlay: TextureRect = %RainbowOverlay
@onready var _rainbow_glow: TextureRect = %RainbowGlow
@onready var _purchase_badge_icon: TextureRect = %PurchaseBadgeIcon


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_sync_lift_root_frame)
	set_process(Engine.is_editor_hint())
	_sync_lift_root_frame()
	_update_editor_preview_state()
	if _did_setup or Engine.is_editor_hint():
		_apply_setup()
	else:
		_apply_visual_state()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not is_node_ready():
		return
	_update_editor_preview_state()


func setup(card_id: String, card_text: String, marked_gain: bool = false) -> void:
	_card_id = card_id
	_card_text = card_text
	_is_marked_gain = marked_gain
	_did_setup = true
	if is_node_ready():
		_apply_setup()


func set_selected(selected: bool, animated: bool = true) -> void:
	if _is_selected == selected:
		return
	_is_selected = selected
	if is_node_ready():
		_refresh_style()
		_refresh_lift(animated)


func set_disabled(disabled: bool, dimmed: bool = false) -> void:
	_is_disabled = disabled
	if is_node_ready():
		if disabled:
			modulate = Color(1, 1, 1, 0.42 if dimmed else 1.0)
			mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			modulate = Color(1, 1, 1, 1)
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_refresh_style()


func get_card_id() -> String:
	return _card_id


func _apply_setup() -> void:
	var effective_card_text: String = _get_effective_card_text()
	custom_minimum_size = _get_card_size_for_mode(effective_card_text)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not _is_disabled else Control.CURSOR_ARROW
	pivot_offset = custom_minimum_size / 2.0

	var card_color: Color = _get_card_color(effective_card_text)
	_normal_style = _build_panel_style(card_color, false)
	_hover_style = _build_panel_style(card_color, true)
	_selected_style = _build_selected_panel_style(card_color, false)
	_selected_hover_style = _build_selected_panel_style(card_color, true)

	_content_root.add_theme_constant_override("margin_left", 7)
	_content_root.add_theme_constant_override("margin_top", 5)
	_content_root.add_theme_constant_override("margin_right", 7)
	_content_root.add_theme_constant_override("margin_bottom", 5)

	var use_atlas: bool = _should_use_atlas()
	_programmatic_face.visible = not use_atlas
	_atlas_texture.visible = use_atlas
	_rainbow_overlay.visible = false
	_rainbow_glow.visible = false

	if use_atlas:
		_content_root.add_theme_constant_override("margin_left", 0)
		_content_root.add_theme_constant_override("margin_top", 0)
		_content_root.add_theme_constant_override("margin_right", 0)
		_content_root.add_theme_constant_override("margin_bottom", 0)
		_atlas_texture.texture = _get_atlas_texture(effective_card_text)
		_atlas_texture.material = _build_rounded_overlay_material(false)
		if effective_card_text == "皇帝牌" or effective_card_text == "♥4":
			_apply_rainbow_special_overlay()
	else:
		_apply_programmatic_face(card_color, effective_card_text)

	_purchase_badge_icon.visible = _is_marked_gain
	tooltip_text = "卖三所得牌" if _is_marked_gain else ""
	_update_editor_preview_state()
	_apply_visual_state()


func _apply_programmatic_face(card_color: Color, card_text: String) -> void:
	var display_rank: String = _get_display_rank(card_text)
	var display_suit: String = _get_display_suit(card_text)
	var is_joker: bool = _is_joker_card(card_text)

	_top_suit_label.text = display_suit
	_top_suit_label.modulate = card_color
	_top_label.text = display_rank
	_top_label.modulate = card_color
	_top_label.add_theme_font_size_override("font_size", 13 if not is_joker else 10)

	_bottom_label.text = display_rank
	_bottom_label.modulate = card_color
	_bottom_label.add_theme_font_size_override("font_size", 13 if not is_joker else 10)
	_bottom_suit_label.text = display_suit
	_bottom_suit_label.modulate = card_color


func _apply_rainbow_special_overlay() -> void:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1.0, 0.16, 0.24, 0.65),
		Color(1.0, 0.56, 0.16, 0.56),
		Color(1.0, 0.9, 0.18, 0.54),
		Color(0.18, 0.88, 0.38, 0.52),
		Color(0.18, 0.6, 1.0, 0.56),
		Color(0.62, 0.24, 1.0, 0.62)
	])
	var gradient_texture: GradientTexture2D = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(1, 1)
	_rainbow_overlay.texture = gradient_texture
	_rainbow_overlay.material = _build_rounded_overlay_material(false)
	_rainbow_overlay.modulate = Color(1, 1, 1, 0.82)
	_rainbow_overlay.visible = true

	_rainbow_glow.texture = gradient_texture
	_rainbow_glow.material = _build_rounded_overlay_material(true)
	_rainbow_glow.modulate = Color(1, 1, 1, 0.46)
	_rainbow_glow.visible = true


func _build_panel_style(card_color: Color, hovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.982, 0.973, 0.937)
	style.corner_radius_top_left = int(CORNER_RADIUS)
	style.corner_radius_top_right = int(CORNER_RADIUS)
	style.corner_radius_bottom_right = int(CORNER_RADIUS)
	style.corner_radius_bottom_left = int(CORNER_RADIUS)
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
	style.bg_color = Color(1, 0.983, 0.925) if hovered else Color(0.995, 0.976, 0.89)
	style.corner_radius_top_left = int(CORNER_RADIUS)
	style.corner_radius_top_right = int(CORNER_RADIUS)
	style.corner_radius_bottom_right = int(CORNER_RADIUS)
	style.corner_radius_bottom_left = int(CORNER_RADIUS)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.894, 0.678, 0.243)
	style.shadow_color = Color(0.894, 0.678, 0.243, 0.34) if hovered else Color(0.894, 0.678, 0.243, 0.24)
	style.shadow_size = 12 if hovered else 8
	return style


func _build_rounded_overlay_material(additive: bool = false) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	var shader: Shader = Shader.new()
	shader.code = "shader_type canvas_item;\nrender_mode blend_add;\n" + RAINBOW_OVERLAY_SHADER_BODY if additive else "shader_type canvas_item;\n" + RAINBOW_OVERLAY_SHADER_BODY
	material.shader = shader
	material.set_shader_parameter("corner_radius_px", CORNER_RADIUS)
	material.set_shader_parameter("rect_size_px", custom_minimum_size)
	material.resource_local_to_scene = true
	return material


func _apply_visual_state() -> void:
	if not is_node_ready():
		return
	if _is_disabled:
		modulate = Color(1, 1, 1, modulate.a if modulate.a < 1.0 else 1.0)
	_refresh_style()
	_refresh_lift(false)


func _refresh_style() -> void:
	if _lift_root == null:
		return
	if _is_selected:
		_lift_root.add_theme_stylebox_override("panel", _selected_hover_style if _is_hovered and not _is_disabled else _selected_style)
	else:
		_lift_root.add_theme_stylebox_override("panel", _hover_style if _is_hovered and not _is_disabled else _normal_style)


func _refresh_lift(animated: bool = true) -> void:
	var target_y: float = SELECTED_LIFT if _is_selected else 0.0
	if not animated:
		_lift_root.position.y = target_y
		_lift_root.size = size
		return
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	_lift_root.size = size
	tween.tween_property(_lift_root, "position:y", target_y, 0.12)


func _on_mouse_entered() -> void:
	if _is_disabled:
		return
	_is_hovered = true
	_refresh_style()


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


func _sync_lift_root_frame() -> void:
	if _lift_root == null:
		return
	_lift_root.position.x = 0
	_lift_root.size = size
	_lift_root.position.y = SELECTED_LIFT if _is_selected else 0
	if _overlay_root != null:
		_overlay_root.position = Vector2.ZERO
		_overlay_root.size = size


func _update_purchase_badge_visibility() -> void:
	if _purchase_badge_icon == null:
		return
	_purchase_badge_icon.visible = _is_marked_gain or (Engine.is_editor_hint() and preview_purchase_badge)


func _update_editor_preview_state() -> void:
	if not is_node_ready():
		return
	_update_purchase_badge_visibility()
	if _purchase_badge_icon != null:
		_purchase_badge_icon.queue_redraw()


func _get_card_color(card_text: String) -> Color:
	if "♥" in card_text or "♦" in card_text or "大王" in card_text or "皇帝" in card_text:
		return Color(0.722, 0.176, 0.196)
	return Color(0.102, 0.118, 0.149)


func _get_atlas_texture(card_text: String) -> Texture2D:
	if Engine.is_editor_hint() and not _did_setup:
		return _get_editor_preview_texture(card_text)
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
	var default_size: Vector2 = Vector2(74, 108)
	if not _should_use_atlas():
		return default_size
	var texture: Texture2D = _get_atlas_texture(card_text)
	if texture == null:
		return default_size
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return default_size
	var target_height: float = 116.0
	var target_width: float = round(target_height * texture_size.x / texture_size.y)
	return Vector2(target_width, target_height)


func _get_effective_card_text() -> String:
	if Engine.is_editor_hint() and not _did_setup:
		return preview_card_text
	return _card_text


func _should_use_atlas() -> bool:
	if Engine.is_editor_hint() and not _did_setup:
		return preview_use_atlas
	var settings: Node = _get_user_settings()
	return settings != null and String(settings.get_render_mode()) == "atlas"


func _get_editor_preview_texture(card_text: String) -> Texture2D:
	if card_text == "大王" or card_text == "皇帝牌":
		return _build_joker_preview_texture(false)
	if card_text == "小王":
		return _build_joker_preview_texture(true)
	return _build_standard_preview_texture(card_text)


func _build_standard_preview_texture(card_text: String) -> Texture2D:
	var suit: String = card_text.left(1)
	var rank: String = card_text.substr(1)
	var column: int = CARD_RANK_ORDER.find(rank)
	var row: int = CARD_SUIT_ORDER.find(suit)
	if column < 0 or row < 0:
		return null
	var cell_width: int = int(CARD_SHEET.get_width() / CARD_COLUMNS)
	var cell_height: int = int(CARD_SHEET.get_height() / CARD_ROWS)
	var region: Rect2i = Rect2i(column * cell_width, row * cell_height, cell_width, cell_height)
	return ImageTexture.create_from_image(CARD_SHEET.get_image().get_region(region))


func _build_joker_preview_texture(inverted: bool) -> Texture2D:
	var cell_width: int = int(JOKER_SHEET.get_width() / JOKER_COLUMNS)
	var cell_height: int = int(JOKER_SHEET.get_height() / JOKER_ROWS)
	var region: Rect2i = Rect2i(0, 0, cell_width, cell_height)
	var image: Image = JOKER_SHEET.get_image().get_region(region)
	if inverted:
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color: Color = image.get_pixel(x, y)
				image.set_pixel(x, y, Color(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a))
	return ImageTexture.create_from_image(image)


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
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("UserSettings")
	return null
