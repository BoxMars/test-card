extends Control

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const CARD_VIEW_SCENE := preload("res://scenes/components/card_view.tscn")
const UI_SKIN := preload("res://scripts/ui_skin.gd")

@onready var mode_option: OptionButton = %ModeOption
@onready var tabs: TabContainer = %Tabs
@onready var joker_grid: GridContainer = %JokerGrid
@onready var joker_note: Label = %JokerNote
@onready var spacing_slider: HSlider = %SpacingSlider
@onready var spacing_value: Label = %SpacingValue
@onready var preview_row: HBoxContainer = %PreviewRow
@onready var rank_gap_slider: HSlider = %RankGapSlider
@onready var rank_gap_value: Label = %RankGapValue
@onready var rank_preview_row: HBoxContainer = %RankPreviewRow
@onready var play_gap_slider: HSlider = %PlayGapSlider
@onready var play_gap_value: Label = %PlayGapValue
@onready var play_preview_row: HBoxContainer = %PlayPreviewRow


func _ready() -> void:
	_apply_ui_skin()
	%BackButton.pressed.connect(_on_back_button_pressed)
	tabs.set_tab_title(0, "间距")
	tabs.set_tab_title(1, "Joker")
	mode_option.item_selected.connect(_on_mode_option_selected)
	spacing_slider.value_changed.connect(_on_spacing_slider_changed)
	rank_gap_slider.value_changed.connect(_on_rank_gap_slider_changed)
	play_gap_slider.value_changed.connect(_on_play_gap_slider_changed)
	_populate_mode_options()
	_populate_joker_grid()
	_refresh_ui()


func _apply_ui_skin() -> void:
	UI_SKIN.apply_tab_container(tabs)
	UI_SKIN.apply_button(%BackButton, "secondary")
	UI_SKIN.apply_button(mode_option, "ghost")
	UI_SKIN.apply_panel($Margin/Root/Tabs/SpacingTab/SpacingPanel, "soft")
	UI_SKIN.apply_panel($Margin/Root/Tabs/SpacingTab/RankGapPanel, "soft")
	UI_SKIN.apply_panel($Margin/Root/Tabs/SpacingTab/PlayGapPanel, "soft")
	UI_SKIN.apply_panel($Margin/Root/Tabs/JokerTab/ModePanel, "soft")
	UI_SKIN.apply_panel($Margin/Root/Tabs/JokerTab/JokerPanel, "default")
	UI_SKIN.apply_panel($Margin/Root/Tabs/SpacingTab/SpacingPanel/SpacingVBox/PreviewPanel, "table")
	UI_SKIN.apply_panel($Margin/Root/Tabs/SpacingTab/RankGapPanel/RankGapVBox/RankPreviewPanel, "table")
	UI_SKIN.apply_panel($Margin/Root/Tabs/SpacingTab/PlayGapPanel/PlayGapVBox/PlayPreviewPanel, "table")
	UI_SKIN.apply_label($Margin/Root/Header/TitleBlock/Title, "title")
	UI_SKIN.apply_label($Margin/Root/Header/TitleBlock/Subtitle, "muted")
	UI_SKIN.apply_label($Margin/Root/Tabs/SpacingTab/SpacingPanel/SpacingVBox/SpacingHeader/SpacingLabel, "section")
	UI_SKIN.apply_label($Margin/Root/Tabs/SpacingTab/RankGapPanel/RankGapVBox/RankGapHeader/RankGapLabel, "section")
	UI_SKIN.apply_label($Margin/Root/Tabs/SpacingTab/PlayGapPanel/PlayGapVBox/PlayGapHeader/PlayGapLabel, "section")
	UI_SKIN.apply_label($Margin/Root/Tabs/JokerTab/JokerPanel/JokerVBox/JokerTitle, "section")
	UI_SKIN.apply_label(joker_note, "muted")


func _populate_mode_options() -> void:
	mode_option.clear()
	mode_option.add_item("程序绘制", 0)
	mode_option.add_item("图集卡面", 1)


func _populate_joker_grid() -> void:
	for child in joker_grid.get_children():
		child.queue_free()

	var settings: Node = _get_user_settings()
	if settings == null:
		return
	var total: int = int(settings.JOKER_COLUMNS) * int(settings.JOKER_ROWS)
	for index in range(total):
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(82, 118)
		button.pressed.connect(_on_joker_button_pressed.bind(index))
		UI_SKIN.apply_button(button, "ghost")

		var texture_rect := TextureRect.new()
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.texture = _get_joker_preview(index)
		button.add_child(texture_rect)

		joker_grid.add_child(button)


func _refresh_ui() -> void:
	var settings: Node = _get_user_settings()
	if settings == null:
		return
	if String(settings.get_render_mode()) == "programmatic":
		mode_option.select(0)
	else:
		mode_option.select(1)

	var selected_index: int = int(settings.get_joker_style_index())
	for index in range(joker_grid.get_child_count()):
		var button := joker_grid.get_child(index) as Button
		button.button_pressed = index == selected_index

	var atlas_enabled: bool = String(settings.get_render_mode()) == "atlas"
	joker_grid.modulate = Color(1, 1, 1, 1 if atlas_enabled else 0.45)
	joker_note.text = "大王使用原图，小王使用反色图，皇帝牌附加彩虹特效。当前样式：%d" % (selected_index + 1)
	spacing_slider.value = float(settings.get_hand_group_separation())
	spacing_value.text = str(int(settings.get_hand_group_separation()))
	rank_gap_slider.value = float(settings.get_hand_rank_gap())
	rank_gap_value.text = str(int(settings.get_hand_rank_gap()))
	play_gap_slider.value = float(settings.get_play_area_separation())
	play_gap_value.text = str(int(settings.get_play_area_separation()))
	_render_spacing_preview()
	_render_rank_gap_preview()
	_render_play_gap_preview()


func _on_mode_option_selected(index: int) -> void:
	var settings: Node = _get_user_settings()
	if settings == null:
		return
	if index == 0:
		settings.set_render_mode("programmatic")
	else:
		settings.set_render_mode("atlas")
	_refresh_ui()


func _on_joker_button_pressed(index: int) -> void:
	var settings: Node = _get_user_settings()
	if settings == null:
		return
	settings.set_joker_style_index(index)
	_refresh_ui()


func _on_spacing_slider_changed(value: float) -> void:
	var settings: Node = _get_user_settings()
	if settings == null:
		return
	settings.set_hand_group_separation(int(value))
	spacing_value.text = str(int(value))
	_render_spacing_preview()


func _on_rank_gap_slider_changed(value: float) -> void:
	var settings: Node = _get_user_settings()
	if settings == null:
		return
	settings.set_hand_rank_gap(int(value))
	rank_gap_value.text = str(int(value))
	_render_rank_gap_preview()


func _on_play_gap_slider_changed(value: float) -> void:
	var settings: Node = _get_user_settings()
	if settings == null:
		return
	settings.set_play_area_separation(int(value))
	play_gap_value.text = str(int(value))
	_render_play_gap_preview()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _get_joker_preview(index: int) -> Texture2D:
	var settings: Node = _get_user_settings()
	if settings == null:
		return null
	var previous_index: int = int(settings.get_joker_style_index())
	settings.set_joker_style_index(index)
	var preview: Texture2D = settings.get_joker_texture(false)
	settings.set_joker_style_index(previous_index)
	return preview


func _get_user_settings() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("UserSettings")
	return null


func _render_spacing_preview() -> void:
	for child in preview_row.get_children():
		child.queue_free()

	var settings: Node = _get_user_settings()
	if settings == null:
		return

	preview_row.add_theme_constant_override("separation", int(settings.get_hand_group_separation()))

	var preview_cards := ["♥7", "♣7", "♦7", "♠7", "小王", "大王", "♥4", "皇帝牌"]
	for card_text_variant in preview_cards:
		var card_text := String(card_text_variant)
		var card_view := CARD_VIEW_SCENE.instantiate() as CardView
		card_view.setup("preview_%s" % card_text, card_text)
		card_view.set_disabled(true, false)
		preview_row.add_child(card_view)


func _render_rank_gap_preview() -> void:
	for child in rank_preview_row.get_children():
		child.queue_free()

	var settings: Node = _get_user_settings()
	if settings == null:
		return

	rank_preview_row.add_theme_constant_override("separation", int(settings.get_hand_rank_gap()))

	var groups := [
		["♥7", "♣7", "♦7"],
		["♠8", "♥8"],
		["小王"],
		["大王"],
		["♥4"],
		["皇帝牌"]
	]
	for group_variant in groups:
		var group_cards: Array = group_variant
		var holder := HBoxContainer.new()
		holder.add_theme_constant_override("separation", int(settings.get_hand_group_separation()))
		rank_preview_row.add_child(holder)

		for card_text_variant in group_cards:
			var card_text := String(card_text_variant)
			var card_view := CARD_VIEW_SCENE.instantiate() as CardView
			card_view.setup("rank_preview_%s" % card_text, card_text)
			card_view.set_disabled(true, false)
			holder.add_child(card_view)


func _render_play_gap_preview() -> void:
	for child in play_preview_row.get_children():
		child.queue_free()

	var settings: Node = _get_user_settings()
	if settings == null:
		return

	play_preview_row.add_theme_constant_override("separation", int(settings.get_play_area_separation()))

	var preview_cards := ["♥7", "♣7", "♦7", "♠7", "小王", "大王", "♥4", "皇帝牌"]
	for card_text_variant in preview_cards:
		var card_text := String(card_text_variant)
		var card_view := CARD_VIEW_SCENE.instantiate() as CardView
		card_view.setup("play_preview_%s" % card_text, card_text)
		card_view.set_disabled(true, false)
		play_preview_row.add_child(card_view)
