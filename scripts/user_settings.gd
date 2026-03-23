extends Node

const RENDER_MODE_PROGRAMMATIC := "programmatic"
const RENDER_MODE_ATLAS := "atlas"
const SETTINGS_PATH := "user://settings.cfg"
const DEV_PLAYER_NAME_FLAG := "--dev-player-name"

const CARD_SHEET := preload("res://figures/card.png")
const JOKER_SHEET := preload("res://figures/jokers.png")

const CARD_COLUMNS := 13
const CARD_ROWS := 4
const JOKER_COLUMNS := 10
const JOKER_ROWS := 16

const CARD_RANK_ORDER := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const CARD_SUIT_ORDER := ["♥", "♣", "♦", "♠"]

var render_mode := RENDER_MODE_ATLAS
var joker_style_index := 0
var hand_group_separation := -44
var hand_rank_gap := 0
var play_area_separation := -44
var user_name := "你"
var runtime_user_name_override := ""

var _card_cache: Dictionary = {}
var _joker_color_cache: Dictionary = {}
var _joker_gray_cache: Dictionary = {}
var _joker_invert_cache: Dictionary = {}


func _ready() -> void:
	_load_settings()
	_apply_runtime_dev_overrides()


func get_render_mode() -> String:
	return render_mode


func set_render_mode(mode: String) -> void:
	if mode != RENDER_MODE_PROGRAMMATIC and mode != RENDER_MODE_ATLAS:
		return
	render_mode = mode
	_save_settings()


func get_joker_style_index() -> int:
	return joker_style_index


func set_joker_style_index(index: int) -> void:
	var max_index: int = JOKER_COLUMNS * JOKER_ROWS - 1
	joker_style_index = clampi(index, 0, max_index)
	_save_settings()


func get_hand_group_separation() -> int:
	return hand_group_separation


func set_hand_group_separation(value: int) -> void:
	hand_group_separation = clampi(value, -60, -10)
	_save_settings()


func get_hand_rank_gap() -> int:
	return hand_rank_gap


func set_hand_rank_gap(value: int) -> void:
	hand_rank_gap = clampi(value, -60, -10)
	_save_settings()


func get_play_area_separation() -> int:
	return play_area_separation


func set_play_area_separation(value: int) -> void:
	play_area_separation = clampi(value, -60, -10)
	_save_settings()


func get_user_name() -> String:
	if runtime_user_name_override != "":
		return runtime_user_name_override
	return user_name


func set_user_name(value: String) -> void:
	var sanitized_name := _sanitize_user_name(value)
	if runtime_user_name_override != "":
		runtime_user_name_override = sanitized_name
		return
	user_name = sanitized_name
	_save_settings()


func get_standard_card_texture(card_text: String) -> Texture2D:
	if _card_cache.has(card_text):
		return _card_cache[card_text]

	var suit: String = card_text.left(1)
	var rank: String = card_text.substr(1)
	var column: int = CARD_RANK_ORDER.find(rank)
	var row: int = CARD_SUIT_ORDER.find(suit)
	if column < 0 or row < 0:
		return null

	var cell_width: int = int(CARD_SHEET.get_width() / CARD_COLUMNS)
	var cell_height: int = int(CARD_SHEET.get_height() / CARD_ROWS)
	var region: Rect2i = Rect2i(column * cell_width, row * cell_height, cell_width, cell_height)
	var texture: Texture2D = _build_region_texture(CARD_SHEET, region)
	_card_cache[card_text] = texture
	return texture


func get_joker_texture(grayscale: bool = false) -> Texture2D:
	var cache: Dictionary = _joker_gray_cache if grayscale else _joker_color_cache
	if cache.has(joker_style_index):
		return cache[joker_style_index]

	var column: int = joker_style_index % JOKER_COLUMNS
	var row: int = int(joker_style_index / JOKER_COLUMNS)
	var cell_width: int = int(JOKER_SHEET.get_width() / JOKER_COLUMNS)
	var cell_height: int = int(JOKER_SHEET.get_height() / JOKER_ROWS)
	var region: Rect2i = Rect2i(column * cell_width, row * cell_height, cell_width, cell_height)
	var texture: Texture2D = _build_region_texture(JOKER_SHEET, region, grayscale)
	cache[joker_style_index] = texture
	return texture


func get_joker_invert_texture() -> Texture2D:
	if _joker_invert_cache.has(joker_style_index):
		return _joker_invert_cache[joker_style_index]

	var column: int = joker_style_index % JOKER_COLUMNS
	var row: int = int(joker_style_index / JOKER_COLUMNS)
	var cell_width: int = int(JOKER_SHEET.get_width() / JOKER_COLUMNS)
	var cell_height: int = int(JOKER_SHEET.get_height() / JOKER_ROWS)
	var region: Rect2i = Rect2i(column * cell_width, row * cell_height, cell_width, cell_height)
	var texture: Texture2D = _build_region_texture(JOKER_SHEET, region, false, true)
	_joker_invert_cache[joker_style_index] = texture
	return texture


func get_all_joker_previews() -> Array:
	var previews: Array = []
	var total: int = JOKER_COLUMNS * JOKER_ROWS
	for index in range(total):
		var previous: int = joker_style_index
		joker_style_index = index
		previews.append(get_joker_texture(false))
		joker_style_index = previous
	return previews


func _build_region_texture(sheet: Texture2D, region: Rect2i, grayscale: bool = false, inverted: bool = false) -> Texture2D:
	var image: Image = sheet.get_image()
	var region_image: Image = image.get_region(region)
	if grayscale:
		_convert_image_to_grayscale(region_image)
	if inverted:
		_invert_image_colors(region_image)
	return ImageTexture.create_from_image(region_image)


func _convert_image_to_grayscale(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color: Color = image.get_pixel(x, y)
			var luminance: float = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			image.set_pixel(x, y, Color(luminance, luminance, luminance, color.a))


func _invert_image_colors(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color: Color = image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a))


func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return
	render_mode = String(config.get_value("cards", "render_mode", render_mode))
	joker_style_index = int(config.get_value("cards", "joker_style_index", joker_style_index))
	hand_group_separation = int(config.get_value("cards", "hand_group_separation", hand_group_separation))
	hand_rank_gap = int(config.get_value("cards", "hand_rank_gap", hand_rank_gap))
	play_area_separation = int(config.get_value("cards", "play_area_separation", play_area_separation))
	user_name = String(config.get_value("profile", "user_name", user_name)).strip_edges()
	if user_name == "":
		user_name = "你"


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("cards", "render_mode", render_mode)
	config.set_value("cards", "joker_style_index", joker_style_index)
	config.set_value("cards", "hand_group_separation", hand_group_separation)
	config.set_value("cards", "hand_rank_gap", hand_rank_gap)
	config.set_value("cards", "play_area_separation", play_area_separation)
	config.set_value("profile", "user_name", user_name)
	config.save(SETTINGS_PATH)


func _apply_runtime_dev_overrides() -> void:
	if not OS.is_debug_build():
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for index in range(args.size()):
		var arg := String(args[index])
		if arg == DEV_PLAYER_NAME_FLAG and index + 1 < args.size():
			runtime_user_name_override = _sanitize_user_name(String(args[index + 1]))
			return
		if arg.begins_with("%s=" % DEV_PLAYER_NAME_FLAG):
			runtime_user_name_override = _sanitize_user_name(arg.trim_prefix("%s=" % DEV_PLAYER_NAME_FLAG))
			return


func _sanitize_user_name(value: String) -> String:
	var trimmed_name := value.strip_edges()
	return trimmed_name if trimmed_name != "" else "你"
