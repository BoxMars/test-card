class_name UISkin
extends RefCounted

const BG_DARK := Color("0d1b1a")
const BG_GREEN := Color("123b35")
const PANEL_DARK := Color("132826")
const PANEL_SOFT := Color("1d3430")
const PANEL_WARM := Color("30271d")
const BORDER_LIGHT := Color("e7d5a3")
const BORDER_GREEN := Color("65b79f")
const TEXT_MAIN := Color("f4efe0")
const TEXT_MUTED := Color("c9bfaa")
const ACCENT_GOLD := Color("f4b860")
const ACCENT_RED := Color("db6a57")
const ACCENT_BLUE := Color("6bc2d8")


static func make_panel_style(
	bg: Color = PANEL_DARK,
	border: Color = BORDER_LIGHT,
	border_width: int = 2,
	corner_radius: int = 14,
	shadow_alpha: float = 0.25
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = Color(0, 0, 0, shadow_alpha)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style


static func make_button_style(
	bg: Color,
	border: Color,
	text_color: Color,
	border_width: int = 2
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


static func apply_button(button: Button, variant: String = "primary") -> void:
	var normal_bg := PANEL_SOFT
	var hover_bg := Color("2a4a44")
	var pressed_bg := Color("10201e")
	var border := BORDER_LIGHT
	var text_color := TEXT_MAIN

	match variant:
		"primary":
			normal_bg = Color("8f412b")
			hover_bg = Color("b05335")
			pressed_bg = Color("6f2e1e")
			border = ACCENT_GOLD
			text_color = TEXT_MAIN
		"secondary":
			normal_bg = Color("224842")
			hover_bg = Color("2a6258")
			pressed_bg = Color("173833")
			border = BORDER_GREEN
			text_color = TEXT_MAIN
		"danger":
			normal_bg = Color("5a2624")
			hover_bg = Color("7a3431")
			pressed_bg = Color("431b19")
			border = ACCENT_RED
			text_color = TEXT_MAIN
		"ghost":
			normal_bg = Color("1a2b29")
			hover_bg = Color("243836")
			pressed_bg = Color("101917")
			border = Color("67847e")
			text_color = TEXT_MUTED

	button.add_theme_stylebox_override("normal", make_button_style(normal_bg, border, text_color))
	button.add_theme_stylebox_override("hover", make_button_style(hover_bg, border.lightened(0.08), text_color))
	button.add_theme_stylebox_override("pressed", make_button_style(pressed_bg, border.darkened(0.12), text_color))
	button.add_theme_stylebox_override("focus", make_button_style(hover_bg, ACCENT_GOLD, text_color, 3))
	button.add_theme_stylebox_override("disabled", make_button_style(normal_bg.darkened(0.25), border.darkened(0.2), text_color.darkened(0.35)))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color.darkened(0.35))
	button.add_theme_font_size_override("font_size", 18)


static func apply_panel(panel: PanelContainer, variant: String = "default") -> void:
	var bg := PANEL_DARK
	var border := BORDER_LIGHT
	var radius := 14

	match variant:
		"default":
			bg = PANEL_DARK
			border = BORDER_LIGHT
		"soft":
			bg = PANEL_SOFT
			border = BORDER_GREEN
		"warm":
			bg = PANEL_WARM
			border = ACCENT_GOLD
		"center":
			bg = Color("102a2f")
			border = ACCENT_BLUE
			radius = 18
		"table":
			bg = Color(0.08, 0.18, 0.17, 0.72)
			border = Color(0.55, 0.83, 0.73, 0.65)
			radius = 18

	panel.add_theme_stylebox_override("panel", make_panel_style(bg, border, 2, radius))


static func apply_label(label: Label, variant: String = "body") -> void:
	match variant:
		"title":
			label.add_theme_color_override("font_color", TEXT_MAIN)
			label.add_theme_font_size_override("font_size", 34)
		"section":
			label.add_theme_color_override("font_color", TEXT_MAIN)
			label.add_theme_font_size_override("font_size", 20)
		"muted":
			label.add_theme_color_override("font_color", TEXT_MUTED)
		"accent":
			label.add_theme_color_override("font_color", ACCENT_GOLD)
		"danger":
			label.add_theme_color_override("font_color", ACCENT_RED)
		"info":
			label.add_theme_color_override("font_color", ACCENT_BLUE.lightened(0.25))
		_:
			label.add_theme_color_override("font_color", TEXT_MAIN)


static func apply_tab_container(tabs: TabContainer) -> void:
	tabs.add_theme_stylebox_override("panel", make_panel_style(Color("0d1b1a"), BORDER_GREEN, 2, 16, 0.15))
	tabs.add_theme_stylebox_override("tab_selected", make_panel_style(Color("7b3b28"), ACCENT_GOLD, 2, 12, 0.18))
	tabs.add_theme_stylebox_override("tab_unselected", make_panel_style(Color("17302c"), Color("5c7c75"), 2, 12, 0.12))
	tabs.add_theme_stylebox_override("tab_hovered", make_panel_style(Color("27433d"), BORDER_GREEN, 2, 12, 0.18))
	tabs.add_theme_color_override("font_selected_color", TEXT_MAIN)
	tabs.add_theme_color_override("font_hovered_color", TEXT_MAIN)
	tabs.add_theme_color_override("font_unselected_color", TEXT_MUTED)
	tabs.add_theme_color_override("font_disabled_color", TEXT_MUTED.darkened(0.35))
	tabs.add_theme_font_size_override("font_size", 18)
