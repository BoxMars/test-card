extends Control

const PLAYER_COUNT := 5
const GAME_SCENE := "res://scenes/main_menu.tscn"
const CARD_VIEW_SCRIPT := preload("res://scripts/card_view.gd")
const UI_SKIN := preload("res://scripts/ui_skin.gd")
const STAGE_SHADER := preload("res://shaders/balatro_stage.gdshader")
const EMPEROR_CARD := "皇帝牌"
const HUMAN_PLAYER_INDEX := 0

@onready var status_label: Label = %StatusLabel
@onready var player_label: Label = %PlayerLabel
@onready var player_role_icon: Label = %PlayerRoleIcon
@onready var player_card_count_label: Label = %PlayerCardCount
@onready var player_countdown_label: Label = %PlayerCountdown
@onready var play_button_row: Control = $Margin/Root/PlayerHandPanel/HandVBox/PlayButtonSlot/PlayButtonRow
@onready var play_actions: Control = $Margin/Root/PlayerHandPanel/HandVBox/PlayButtonSlot/PlayButtonRow
@onready var play_button: Button = %PlayButton
@onready var hint_button: Button = %HintButton
@onready var pass_button: Button = %PassButton
@onready var player_play_cards: HBoxContainer = %PlayerPlayCards
@onready var top_hand_row: HBoxContainer = $Margin/Root/PlayerHandPanel/HandVBox/HandRows/TopHandRow
@onready var bottom_hand_row: HBoxContainer = %BottomHandRow
@onready var background_rect: ColorRect = $Background
@onready var table_glow: ColorRect = $TableGlow

const CARD_ORDER := {
	"4": 0,
	"大王": 1,
	"小王": 2,
	"2": 3,
	"A": 4,
	"K": 5,
	"Q": 6,
	"J": 7,
	"10": 8,
	"9": 9,
	"8": 10,
	"7": 11,
	"6": 12,
	"5": 13,
	"3": 14
}

const SUIT_ORDER := {
	"♠": 0,
	"♥": 1,
	"♣": 2,
	"♦": 3
}

const PLAYER_PLAY_SCALE := 0.66
const OPPONENT_PLAY_SCALE := 0.5
const SPECIAL_RANK_EXTRA_GAP := 0

var players: Array = []
var selected_card_ids: Array = []
var selected_anchor_rank := ""
var hand_card_lookup: Dictionary = {}
var current_turn_index := 0
var emperor_player_index := -1
var last_play: Dictionary = {}
var consecutive_passes := 0
var opponent_slots: Array = []
var ai_turn_token := 0
var hint_cycle_signature := ""
var hint_cycle_options: Array = []
var hint_cycle_index := -1
var suppress_ai_autorun := false
var turn_deadline_msec := 0
var turn_timeout_triggered := false


func _ready() -> void:
	_bind_player_nodes()
	_apply_ui_skin()
	_apply_background_shader()
	_deal_cards()
	set_process(true)


func _bind_player_nodes() -> void:
	var user_name := _get_user_name()
	players = [
		{
			"name": user_name,
			"type": "human",
			"role": "",
			"passed": false,
			"shown_play": [],
			"cards": []
		},
		{
			"name": "AI 1",
			"type": "ai",
			"role": "",
			"passed": false,
			"shown_play": [],
			"cards": []
		},
		{
			"name": "AI 2",
			"type": "ai",
			"role": "",
			"passed": false,
			"shown_play": [],
			"cards": []
		},
		{
			"name": "AI 3",
			"type": "ai",
			"role": "",
			"passed": false,
			"shown_play": [],
			"cards": []
		},
		{
			"name": "AI 4",
			"type": "ai",
			"role": "",
			"passed": false,
			"shown_play": [],
			"cards": []
		}
	]
	opponent_slots = [
		{
			# Counterclockwise from the human player: right-bottom, right-top, left-top, left-bottom.
			"player_index": 1,
			"panel": $Margin/Root/TableArea/RightColumn/Opponent5,
			"count_side": "left",
			"name_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Info/Name,
			"turn_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Info/TurnBadge,
			"countdown_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Countdown,
			"avatar_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Info/Avatar,
			"role_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Info/RoleBadge,
			"pass_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/PassLabel,
			"play_container": $Margin/Root/TableArea/RightColumn/Opponent5/Row/PlayRow
		},
		{
			"player_index": 2,
			"panel": $Margin/Root/TableArea/RightColumn/Opponent4,
			"count_side": "left",
			"name_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Info/Name,
			"turn_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Info/TurnBadge,
			"countdown_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Countdown,
			"avatar_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Info/Avatar,
			"role_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Info/RoleBadge,
			"pass_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/PassLabel,
			"play_container": $Margin/Root/TableArea/RightColumn/Opponent4/Row/PlayRow
		},
		{
			"player_index": 3,
			"panel": $Margin/Root/TableArea/LeftColumn/Opponent2,
			"count_side": "right",
			"name_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Info/Name,
			"turn_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Info/TurnBadge,
			"countdown_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Countdown,
			"avatar_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Info/Avatar,
			"role_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Info/RoleBadge,
			"pass_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/PassLabel,
			"play_container": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/PlayRow
		},
		{
			"player_index": 4,
			"panel": $Margin/Root/TableArea/LeftColumn/Opponent3,
			"count_side": "right",
			"name_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Info/Name,
			"turn_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Info/TurnBadge,
			"countdown_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Countdown,
			"avatar_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Info/Avatar,
			"role_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Info/RoleBadge,
			"pass_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/PassLabel,
			"play_container": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/PlayRow
		}
	]


func _deal_cards() -> void:
	players[HUMAN_PLAYER_INDEX]["name"] = _get_user_name()
	for player in players:
		player["cards"] = []
	selected_card_ids.clear()
	selected_anchor_rank = ""
	hand_card_lookup.clear()
	current_turn_index = 0
	emperor_player_index = -1
	last_play = {}
	consecutive_passes = 0
	ai_turn_token += 1
	turn_deadline_msec = 0
	turn_timeout_triggered = false
	_reset_hint_cycle()
	for player in players:
		player["role"] = ""
		player["passed"] = false
		player["shown_play"] = []

	var threes = CardDeck.build_special_threes()
	for index in range(players.size()):
		players[index]["cards"].append(threes[index])

	var deck = CardDeck.build_main_deck()
	var next_player := 0

	for card in deck:
		players[next_player]["cards"].append(card)
		next_player = (next_player + 1) % PLAYER_COUNT

	for player in players:
		player["cards"].sort_custom(Callable(self, "_sort_cards"))

	_assign_roles()
	current_turn_index = emperor_player_index
	_start_turn_countdown()
	_refresh_ui(deck.size() + threes.size())


func _refresh_ui(total_cards: int) -> void:
	_reset_hint_cycle()
	var human_player = players[HUMAN_PLAYER_INDEX]
	var current_hand = human_player["cards"]
	var human_shown_play: Array = human_player.get("shown_play", [])
	if current_turn_index == HUMAN_PLAYER_INDEX and int(last_play.get("player_index", -1)) != HUMAN_PLAYER_INDEX:
		human_shown_play = []

	_update_opponent_slots()
	_render_play_cards(player_play_cards, human_shown_play, PLAYER_PLAY_SCALE, 1, false, "right")

	if last_play.is_empty():
		status_label.text = "已将 %d 张牌发给 %d 名玩家，其中 3 共 5 张且每人 1 张。" % [total_cards, PLAYER_COUNT]
	player_label.text = _format_player_name(HUMAN_PLAYER_INDEX)
	player_role_icon.text = _get_role_icon(HUMAN_PLAYER_INDEX)
	player_countdown_label.text = _get_countdown_text(HUMAN_PLAYER_INDEX)
	player_card_count_label.text = "剩余 %d 张" % current_hand.size()
	_render_current_hand(current_hand)
	if not selected_card_ids.is_empty():
		call_deferred("_refresh_selection_state")
	_update_action_buttons()
	if not suppress_ai_autorun:
		_maybe_run_ai_turn()


func _update_opponent_slots() -> void:
	for slot in opponent_slots:
		var player_index = int(slot["player_index"])
		var player = players[player_index]
		slot["name_label"].text = _format_player_name(player_index)
		slot["turn_label"].text = ""
		slot["countdown_label"].text = _get_countdown_text(player_index)
		slot["avatar_label"].text = _format_player_avatar(player_index)
		slot["role_label"].text = ""
		var pass_label: Label = slot.get("pass_label")
		if pass_label != null:
			pass_label.visible = bool(player.get("passed", false))
		_render_play_cards(
			slot["play_container"],
			player.get("shown_play", []),
			OPPONENT_PLAY_SCALE,
			slot["play_container"].alignment,
			false,
			String(slot.get("count_side", "right"))
		)


func _apply_ui_skin() -> void:
	var empty_style := StyleBoxEmpty.new()
	UI_SKIN.apply_button($Margin/Root/Header/Actions/DealButton, "secondary")
	UI_SKIN.apply_button($Margin/Root/Header/Actions/MenuButton, "ghost")
	UI_SKIN.apply_button(pass_button, "ghost")
	UI_SKIN.apply_button(play_button, "primary")
	UI_SKIN.apply_button(hint_button, "secondary")
	$Margin/Root/PlayerHandPanel.add_theme_stylebox_override("panel", empty_style)
	UI_SKIN.apply_label($Margin/Root/Header/TitleBlock/Title, "title")
	UI_SKIN.apply_label(status_label, "muted")
	UI_SKIN.apply_label(player_label, "section")
	UI_SKIN.apply_label(player_role_icon, "accent")
	UI_SKIN.apply_label(player_countdown_label, "info")
	player_countdown_label.add_theme_font_size_override("font_size", 28)
	player_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	UI_SKIN.apply_label(player_card_count_label, "section")
	for slot in opponent_slots:
		var panel: PanelContainer = slot["panel"]
		panel.add_theme_stylebox_override("panel", empty_style)
		UI_SKIN.apply_label(slot["turn_label"], "accent")
		var countdown_label: Label = slot.get("countdown_label")
		if countdown_label != null:
			UI_SKIN.apply_label(countdown_label, "info")
			countdown_label.add_theme_font_size_override("font_size", 28)
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
		UI_SKIN.apply_label(slot["avatar_label"], "accent")
		UI_SKIN.apply_label(slot["name_label"], "section")
		UI_SKIN.apply_label(slot["role_label"], "accent")
		var pass_label: Label = slot.get("pass_label")
		if pass_label != null:
			UI_SKIN.apply_label(pass_label, "muted")
			pass_label.add_theme_font_size_override("font_size", 22)

func _apply_background_shader() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = STAGE_SHADER
	shader_material.set_shader_parameter("colour_1", Color(0.05, 0.10, 0.11, 1.0))
	shader_material.set_shader_parameter("colour_2", Color(0.06, 0.31, 0.25, 1.0))
	shader_material.set_shader_parameter("colour_3", Color(0.86, 0.41, 0.21, 1.0))
	shader_material.set_shader_parameter("contrast", 1.18)
	shader_material.set_shader_parameter("spin_amount", 0.22)
	background_rect.material = shader_material
	table_glow.color = Color(0.10, 0.30, 0.26, 0.62)

func _get_player_identity_text(player_index: int) -> String:
	return String(players[player_index].get("role", ""))


func _get_role_icon(player_index: int) -> String:
	var role := String(players[player_index].get("role", ""))
	match role:
		"皇帝":
			return "👑"
		"独保":
			return "👑🗡"
		"侍卫":
			return "🗡"
		"革命党":
			return "⚑"
		_:
			return ""


func _get_countdown_text(player_index: int) -> String:
	if player_index != current_turn_index or turn_deadline_msec <= 0:
		return ""
	return "%ds" % _get_turn_countdown_seconds()


func _render_current_hand(hand: Array) -> void:
	for child in top_hand_row.get_children():
		child.queue_free()
	for child in bottom_hand_row.get_children():
		child.queue_free()
	hand_card_lookup.clear()

	var indexed_hand := _build_indexed_hand(hand)
	var grouped_cards := _group_cards_by_rank(indexed_hand)
	var split_result := _split_groups_for_rows(grouped_cards)
	var top_groups = split_result[0]
	var bottom_groups = split_result[1]

	_render_groups_in_row(top_hand_row, top_groups)
	_render_groups_in_row(bottom_hand_row, bottom_groups)


func _render_groups_in_row(row: HBoxContainer, groups: Array) -> void:
	var hand_group_separation := _get_hand_group_separation()
	row.add_theme_constant_override("separation", _get_hand_rank_gap())
	for index in range(groups.size()):
		var group: Array = groups[index]
		var rank_group := HBoxContainer.new()
		rank_group.add_theme_constant_override("separation", hand_group_separation)
		row.add_child(rank_group)

		for card_data in group:
			var card_view := CARD_VIEW_SCRIPT.new()
			var card_id = card_data["id"]
			var card_text = card_data["text"]
			var rank = card_data["rank"]
			card_view.setup(card_id, card_text)
			card_view.card_pressed.connect(_on_card_pressed)
			card_view.set_selected(selected_card_ids.has(card_id), false)
			card_view.set_disabled(not _can_select_rank(rank, card_id))
			rank_group.add_child(card_view)
			hand_card_lookup[card_id] = card_data

		if index < groups.size() - 1:
			var current_rank := String(group[0]["rank"])
			var next_group: Array = groups[index + 1]
			var next_rank := String(next_group[0]["rank"])
			var extra_gap := 0
			if _needs_extra_gap_between_ranks(current_rank, next_rank):
				extra_gap = SPECIAL_RANK_EXTRA_GAP
			if extra_gap != 0:
				var spacer := Control.new()
				spacer.custom_minimum_size = Vector2(extra_gap, 0)
				spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(spacer)


func _group_cards_by_rank(hand: Array) -> Array:
	var groups: Array = []
	var current_group: Array = []
	var current_rank := ""

	for card_data_variant in hand:
		var card_data = card_data_variant
		var rank = card_data["rank"]
		if current_group.is_empty() or rank == current_rank:
			current_group.append(card_data)
		else:
			groups.append(current_group)
			current_group = [card_data]
		current_rank = rank

	if not current_group.is_empty():
		groups.append(current_group)

	return groups


func _split_groups_for_rows(groups: Array) -> Array:
	var top_groups: Array = []
	var bottom_groups: Array = []
	var total_cards := 0

	for group in groups:
		total_cards += group.size()

	var target_bottom_count := int(ceil(total_cards / 2.0))
	var current_bottom_count := 0

	for group_index in range(groups.size() - 1, -1, -1):
		var group: Array = groups[group_index]
		if current_bottom_count < target_bottom_count:
			bottom_groups.push_front(group)
			current_bottom_count += group.size()
		else:
			top_groups.push_front(group)

	if bottom_groups.is_empty() and not top_groups.is_empty():
		bottom_groups.append(top_groups.pop_back())

	return [top_groups, bottom_groups]


func _build_indexed_hand(hand: Array) -> Array:
	var indexed_hand: Array = []
	var duplicate_count: Dictionary = {}

	for card_variant in hand:
		var card_text := String(card_variant)
		var count = int(duplicate_count.get(card_text, 0))
		duplicate_count[card_text] = count + 1
		indexed_hand.append(
			{
				"id": "%s#%d" % [card_text, count],
				"text": card_text,
				"rank": _get_rank(card_text)
			}
		)

	return indexed_hand


func _on_card_pressed(card_id: String, card_text: String) -> void:
	_reset_hint_cycle()
	var clicked_rank := _get_rank(card_text)
	if not _can_select_rank(clicked_rank, card_id):
		return

	if selected_card_ids.has(card_id):
		selected_card_ids.erase(card_id)
	else:
		if _should_auto_complete_follow_play() and not _is_joker_rank(clicked_rank):
			var auto_selected := _build_auto_follow_selection(clicked_rank, card_id)
			if not auto_selected.is_empty():
				selected_card_ids = auto_selected
				selected_card_ids.sort()
				_refresh_selection_state()
				return
		if not _is_joker_rank(clicked_rank):
			_remove_selected_non_jokers_except(clicked_rank)
		var rank_ids := _get_card_ids_for_rank(clicked_rank)
		for rank_id in rank_ids:
			if not selected_card_ids.has(rank_id):
				selected_card_ids.append(rank_id)

	selected_card_ids.sort()
	_refresh_selection_state()


func _refresh_selection_state() -> void:
	var filtered_selection: Array = []
	for card_id in selected_card_ids:
		if hand_card_lookup.has(card_id):
			filtered_selection.append(card_id)
	selected_card_ids = filtered_selection

	selected_anchor_rank = _resolve_anchor_rank()
	_update_card_view_states(top_hand_row)
	_update_card_view_states(bottom_hand_row)
	_update_action_buttons()


func _update_card_view_states(row: HBoxContainer) -> void:
	for rank_group in row.get_children():
		for child in rank_group.get_children():
			if child is CardView:
				var card_view := child as CardView
				var card_id = card_view.get_card_id()
				var card_data = hand_card_lookup.get(card_id, {})
				var rank = String(card_data.get("rank", ""))
				card_view.set_selected(selected_card_ids.has(card_id))
				card_view.set_disabled(not _can_select_rank(rank, card_id))


func _resolve_anchor_rank() -> String:
	for card_id in selected_card_ids:
		var card_data = hand_card_lookup.get(card_id, {})
		var rank = String(card_data.get("rank", ""))
		if rank != "" and not _is_joker_rank(rank):
			return rank
	if selected_card_ids.is_empty():
		return ""
	return "joker"


func _can_select_rank(rank: String, card_id: String) -> bool:
	if rank == "3" and not _can_play_three_for_player(HUMAN_PLAYER_INDEX):
		return selected_card_ids.has(card_id)
	return true


func _get_card_ids_for_rank(rank: String) -> Array:
	var ids: Array = []
	for card_id in hand_card_lookup.keys():
		var card_data = hand_card_lookup[card_id]
		if card_data["rank"] == rank:
			ids.append(card_id)
	ids.sort()
	return ids


func _remove_selected_non_jokers_except(rank_to_keep: String) -> void:
	var remaining_ids: Array = []
	for selected_id in selected_card_ids:
		var card_data = hand_card_lookup.get(selected_id, {})
		var selected_rank = String(card_data.get("rank", ""))
		if _is_joker_rank(selected_rank) or selected_rank == rank_to_keep:
			remaining_ids.append(selected_id)
	selected_card_ids = remaining_ids


func _is_joker_rank(rank: String) -> bool:
	return rank == "大王" or rank == "小王" or rank == "4"


func _should_auto_complete_follow_play() -> bool:
	if last_play.is_empty():
		return false
	return int(last_play.get("player_index", -1)) != HUMAN_PLAYER_INDEX


func _build_auto_follow_selection(clicked_rank: String, clicked_card_id: String) -> Array:
	var hand = players[HUMAN_PLAYER_INDEX]["cards"]
	var indexed_hand = _build_indexed_hand(hand)
	var groups = _group_cards_by_rank(indexed_hand)
	var candidate_plays := _enumerate_candidate_plays(HUMAN_PLAYER_INDEX, indexed_hand, groups)
	var best_play: Dictionary = {}

	for candidate in candidate_plays:
		if not _can_beat_last_play(candidate):
			continue
		if not _candidate_matches_click(candidate, clicked_rank, clicked_card_id):
			continue
		if best_play.is_empty() or _is_play_weaker(candidate, best_play):
			best_play = candidate

	if best_play.is_empty():
		return []

	return best_play.get("card_ids", []).duplicate()


func _candidate_matches_click(candidate: Dictionary, clicked_rank: String, clicked_card_id: String) -> bool:
	var card_ids: Array = candidate.get("card_ids", [])
	if _is_joker_rank(clicked_rank):
		return card_ids.has(clicked_card_id)
	return String(candidate.get("base_rank", "")) == clicked_rank


func _can_play_three() -> bool:
	return _can_play_three_for_player(current_turn_index)


func _can_play_three_for_player(player_index: int) -> bool:
	var current_cards = players[player_index]["cards"]
	for card in current_cards:
		if _get_rank(String(card)) != "3":
			return false
	return true


func _update_action_buttons() -> void:
	var is_human_turn := current_turn_index == HUMAN_PLAYER_INDEX
	var can_play := false
	if is_human_turn and not selected_card_ids.is_empty():
		var play_state := _build_play_state_from_selection()
		can_play = not play_state.is_empty() and _can_beat_last_play(play_state)
	var can_pass := is_human_turn and not last_play.is_empty() and int(last_play.get("player_index", -1)) != HUMAN_PLAYER_INDEX
	play_button_row.visible = true
	play_actions.modulate = Color(1, 1, 1, 1.0 if is_human_turn else 0.0)
	play_actions.mouse_filter = Control.MOUSE_FILTER_STOP if is_human_turn else Control.MOUSE_FILTER_IGNORE
	play_button.disabled = not can_play
	hint_button.disabled = not is_human_turn
	pass_button.disabled = not can_pass


func _sort_cards(a: String, b: String) -> bool:
	var rank_a := _get_rank(a)
	var rank_b := _get_rank(b)
	var order_a: int = CARD_ORDER.get(rank_a, 999)
	var order_b: int = CARD_ORDER.get(rank_b, 999)
	if order_a != order_b:
		return order_a < order_b

	var suit_a: int = SUIT_ORDER.get(_get_suit(a), 999)
	var suit_b: int = SUIT_ORDER.get(_get_suit(b), 999)
	return suit_a < suit_b


func _get_rank(card: String) -> String:
	if card == EMPEROR_CARD:
		return "大王"
	if card == "大王" or card == "小王":
		return card
	return card.substr(1)


func _get_suit(card: String) -> String:
	if card == "大王" or card == "小王":
		return ""
	return card.left(1)


func _on_deal_button_pressed() -> void:
	_deal_cards()


func _on_play_button_pressed() -> void:
	if current_turn_index != HUMAN_PLAYER_INDEX:
		return
	if selected_card_ids.is_empty():
		return
	if selected_anchor_rank == "3" and not _can_play_three():
		status_label.text = "3 必须留到其他牌都出完后才能打出。"
		return
	var play_state := _build_play_state_from_selection()
	if play_state.is_empty():
		status_label.text = "出牌只能有一种普通点数，大小王可附带，也可单独出。"
		return
	if not _can_beat_last_play(play_state):
		status_label.text = "要牌必须与上家张数一致，且逐张都更大。"
		return

	var current_cards = players[current_turn_index]["cards"]
	var removal_ids := selected_card_ids.duplicate()
	removal_ids.sort_custom(Callable(self, "_sort_card_ids_desc"))

	for card_id in removal_ids:
		var parts: PackedStringArray = String(card_id).rsplit("#", true, 1)
		if parts.size() != 2:
			continue
		var card_text: String = parts[0]
		var occurrence := int(parts[1])
		var match_index := _find_card_index_by_occurrence(current_cards, card_text, occurrence)
		if match_index >= 0:
			current_cards.remove_at(match_index)

	selected_card_ids.clear()
	selected_anchor_rank = ""
	players[current_turn_index]["cards"] = current_cards
	players[current_turn_index]["passed"] = false
	players[current_turn_index]["shown_play"] = _extract_played_texts(removal_ids)
	last_play = play_state
	last_play["player_index"] = current_turn_index
	consecutive_passes = 0
	status_label.text = "%s 出牌：%s" % [_format_player_name(current_turn_index), play_state["display_text"]]
	if current_cards.is_empty():
		var win_text := "%s 获胜。" % _format_player_name(current_turn_index)
		last_play = {}
		turn_deadline_msec = 0
		_clear_displayed_plays()
		_refresh_ui(_get_total_card_count())
		status_label.text = win_text
		return

	_advance_turn()
	_refresh_ui(_get_total_card_count())


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_pass_button_pressed() -> void:
	if current_turn_index != HUMAN_PLAYER_INDEX:
		return
	if last_play.is_empty():
		return
	if last_play.get("player_index", -1) == current_turn_index:
		return
	selected_card_ids.clear()
	selected_anchor_rank = ""
	players[current_turn_index]["shown_play"] = []
	players[current_turn_index]["passed"] = true
	consecutive_passes += 1
	status_label.text = "%s 不要。" % _format_player_name(current_turn_index)
	if consecutive_passes >= PLAYER_COUNT - 1:
		consecutive_passes = 0
		current_turn_index = last_play.get("player_index", current_turn_index)
		_start_turn_countdown()
		last_play = {}
		_clear_displayed_plays()
		var reset_text := "其余玩家都不要，重新由 %s 领出。" % _format_player_name(current_turn_index)
		_refresh_ui(_get_total_card_count())
		status_label.text = reset_text
	else:
		_advance_turn()
		_refresh_ui(_get_total_card_count())


func _find_card_index_by_occurrence(cards: Array, card_text: String, occurrence: int) -> int:
	var seen := 0
	for index in range(cards.size()):
		if String(cards[index]) == card_text:
			if seen == occurrence:
				return index
			seen += 1
	return -1


func _extract_played_texts(card_ids: Array) -> Array:
	var played_cards: Array = []
	for card_id in card_ids:
		var parts: PackedStringArray = String(card_id).rsplit("#", true, 1)
		if not parts.is_empty():
			played_cards.append(parts[0])
	return played_cards


func _sort_card_ids_desc(a: String, b: String) -> bool:
	return a > b


func _assign_roles() -> void:
	emperor_player_index = -1
	for index in range(players.size()):
		var cards = players[index]["cards"]
		var has_emperor := false
		var has_guard := false
		for card in cards:
			var card_text := String(card)
			if card_text == EMPEROR_CARD:
				has_emperor = true
			elif _get_rank(card_text) == "4":
				has_guard = true
		if has_emperor:
			emperor_player_index = index
		if has_emperor and has_guard:
			players[index]["role"] = "独保"
		elif has_emperor:
			players[index]["role"] = "皇帝"
		elif has_guard:
			players[index]["role"] = "侍卫"
		else:
			players[index]["role"] = "革命党"


func _format_player_name(player_index: int) -> String:
	return String(players[player_index]["name"])


func _format_player_avatar(player_index: int) -> String:
	return _get_role_icon(player_index)


func _get_emperor_display_name() -> String:
	if emperor_player_index < 0:
		return "待定"
	return _format_player_name(emperor_player_index)


func _get_last_play_text() -> String:
	if last_play.is_empty():
		return "上家出牌：尚未开始"
	var display_text := String(last_play.get("display_text", ""))
	return "上家出牌：%s" % display_text


func _build_play_state_from_selection() -> Dictionary:
	var base_rank := ""
	var base_count := 0
	var joker_ranks: Array = []
	var display_cards: Array = []
	var selected_ids := selected_card_ids.duplicate()

	for card_id in selected_ids:
		var card_data = hand_card_lookup.get(card_id, {})
		if card_data.is_empty():
			continue
		var rank := String(card_data.get("rank", ""))
		var text := String(card_data.get("text", ""))
		display_cards.append(text)
		if _is_joker_rank(rank):
			joker_ranks.append(rank)
		else:
			if base_rank == "":
				base_rank = rank
			elif base_rank != rank:
				return {}
			base_count += 1

	joker_ranks.sort_custom(Callable(self, "_sort_jokers_ascending"))
	display_cards.sort_custom(Callable(self, "_sort_cards"))
	var card_orders := _build_card_orders(base_rank, base_count, joker_ranks)

	return {
		"base_rank": base_rank,
		"base_count": base_count,
		"joker_ranks": joker_ranks,
		"card_orders": card_orders,
		"card_count": selected_ids.size(),
		"card_ids": selected_ids,
		"display_text": ", ".join(display_cards)
	}


func _can_beat_last_play(play_state: Dictionary) -> bool:
	if last_play.is_empty():
		return int(play_state.get("card_count", 0)) > 0

	var current_orders: Array = play_state.get("card_orders", [])
	var last_orders: Array = last_play.get("card_orders", [])
	if current_orders.size() != last_orders.size():
		return false

	for index in range(last_orders.size()):
		if int(current_orders[index]) >= int(last_orders[index]):
			return false

	return true


func _get_rank_order(rank: String) -> int:
	if rank == "":
		return 999
	return int(CARD_ORDER.get(rank, 999))


func _get_joker_orders(joker_ranks: Array) -> Array:
	var orders: Array = []
	for rank in joker_ranks:
		orders.append(_get_rank_order(String(rank)))
	return orders


func _build_card_orders(base_rank: String, base_count: int, joker_ranks: Array) -> Array:
	var orders: Array = []
	if base_rank != "":
		var base_order := _get_rank_order(base_rank)
		for index in range(base_count):
			orders.append(base_order)
	for rank in joker_ranks:
		orders.append(_get_rank_order(String(rank)))
	orders.sort()
	return orders


func _sort_jokers_ascending(a: String, b: String) -> bool:
	return _get_rank_order(a) < _get_rank_order(b)


func _advance_turn() -> void:
	current_turn_index = (current_turn_index + 1) % PLAYER_COUNT
	_start_turn_countdown()


func _get_total_card_count() -> int:
	var total := 0
	for player in players:
		total += player["cards"].size()
	return total


func _maybe_run_ai_turn() -> void:
	if current_turn_index == HUMAN_PLAYER_INDEX:
		return
	if players[current_turn_index]["cards"].is_empty():
		return
	ai_turn_token += 1
	var token := ai_turn_token
	_run_ai_turn(token)


func _run_ai_turn(token: int) -> void:
	if not last_play.is_empty():
		players[current_turn_index]["shown_play"] = []
		players[current_turn_index]["passed"] = false
		suppress_ai_autorun = true
		_refresh_ui(_get_total_card_count())
		suppress_ai_autorun = false
		if token != ai_turn_token:
			return

	await get_tree().create_timer(1.0).timeout
	if token != ai_turn_token:
		return
	if current_turn_index == HUMAN_PLAYER_INDEX:
		return
	if turn_timeout_triggered:
		return
	var ai_action := _choose_ai_action()
	if ai_action.get("type", "pass") == "play":
		_execute_ai_play(ai_action)
	else:
		_execute_ai_pass()


func _choose_ai_action() -> Dictionary:
	return _find_min_play_for_player(current_turn_index)


func _build_play_state_from_card_ids(card_ids: Array, indexed_hand: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for card_data in indexed_hand:
		lookup[card_data["id"]] = card_data

	var base_rank := ""
	var base_count := 0
	var joker_ranks: Array = []
	var display_cards: Array = []

	for card_id in card_ids:
		var card_data = lookup.get(card_id, {})
		if card_data.is_empty():
			continue
		var rank = String(card_data["rank"])
		var text = String(card_data["text"])
		display_cards.append(text)
		if _is_joker_rank(rank):
			joker_ranks.append(rank)
		else:
			if base_rank == "":
				base_rank = rank
			elif base_rank != rank:
				return {}
			base_count += 1

	joker_ranks.sort_custom(Callable(self, "_sort_jokers_ascending"))
	display_cards.sort_custom(Callable(self, "_sort_cards"))
	var card_orders := _build_card_orders(base_rank, base_count, joker_ranks)

	return {
		"base_rank": base_rank,
		"base_count": base_count,
		"joker_ranks": joker_ranks,
		"card_orders": card_orders,
		"card_count": card_ids.size(),
		"card_ids": card_ids.duplicate(),
		"display_text": ", ".join(display_cards)
	}


func _execute_ai_play(ai_action: Dictionary) -> void:
	var current_cards = players[current_turn_index]["cards"]
	var removal_ids = ai_action.get("card_ids", []).duplicate()
	removal_ids.sort_custom(Callable(self, "_sort_card_ids_desc"))

	for card_id in removal_ids:
		var parts: PackedStringArray = String(card_id).rsplit("#", true, 1)
		if parts.size() != 2:
			continue
		var card_text: String = parts[0]
		var occurrence := int(parts[1])
		var match_index := _find_card_index_by_occurrence(current_cards, card_text, occurrence)
		if match_index >= 0:
			current_cards.remove_at(match_index)

	players[current_turn_index]["cards"] = current_cards
	last_play = ai_action.get("play_state", {})
	players[current_turn_index]["passed"] = false
	players[current_turn_index]["shown_play"] = _extract_played_texts(removal_ids)
	last_play["player_index"] = current_turn_index
	consecutive_passes = 0

	var action_text := "%s 出牌：%s" % [_format_player_name(current_turn_index), String(last_play.get("display_text", ""))]
	if current_cards.is_empty():
		last_play = {}
		turn_deadline_msec = 0
		_clear_displayed_plays()
		_refresh_ui(_get_total_card_count())
		status_label.text = "%s 获胜。" % _format_player_name(current_turn_index)
		return

	_advance_turn()
	_refresh_ui(_get_total_card_count())
	status_label.text = action_text


func _execute_ai_pass() -> void:
	consecutive_passes += 1
	players[current_turn_index]["shown_play"] = []
	players[current_turn_index]["passed"] = true
	var pass_text := "%s 不要。" % _format_player_name(current_turn_index)
	if consecutive_passes >= PLAYER_COUNT - 1:
		consecutive_passes = 0
		current_turn_index = int(last_play.get("player_index", current_turn_index))
		_start_turn_countdown()
		last_play = {}
		_clear_displayed_plays()
		_refresh_ui(_get_total_card_count())
		status_label.text = "其余玩家都不要，重新由 %s 领出。" % _format_player_name(current_turn_index)
		return

	_advance_turn()
	_refresh_ui(_get_total_card_count())
	status_label.text = pass_text


func _clear_displayed_plays() -> void:
	for player in players:
		player["passed"] = false
		player["shown_play"] = []


func _process(_delta: float) -> void:
	if current_turn_index < 0 or current_turn_index >= players.size():
		return
	if turn_deadline_msec <= 0:
		return
	if turn_timeout_triggered:
		return
	if Time.get_ticks_msec() < turn_deadline_msec:
		_update_turn_labels()
		return
	turn_timeout_triggered = true
	ai_turn_token += 1
	_handle_turn_timeout()


func _find_min_play_for_player(player_index: int) -> Dictionary:
	var hand = players[player_index]["cards"]
	var indexed_hand = _build_indexed_hand(hand)
	var groups = _group_cards_by_rank(indexed_hand)
	if last_play.is_empty():
		return _find_lead_play_for_player(player_index, indexed_hand, groups)
	var candidate_plays := _enumerate_candidate_plays(player_index, indexed_hand, groups)
	var best_play: Dictionary = {}

	for candidate in candidate_plays:
		if not _can_beat_last_play(candidate):
			continue
		if best_play.is_empty() or _is_play_weaker(candidate, best_play):
			best_play = candidate

	if best_play.is_empty():
		return {}

	return {
		"type": "play",
		"card_ids": best_play.get("card_ids", []).duplicate(),
		"play_state": best_play,
		"display_text": String(best_play.get("display_text", ""))
	}


func _find_lead_play_for_player(player_index: int, indexed_hand: Array, groups: Array) -> Dictionary:
	for group_index in range(groups.size() - 1, -1, -1):
		var group: Array = groups[group_index]
		var rank := String(group[0]["rank"])
		if _is_joker_rank(rank):
			continue
		if rank == "3" and not _can_play_three_for_player(player_index):
			continue

		var group_ids: Array = []
		for card_data in group:
			group_ids.append(card_data["id"])

		var play_state := _build_play_state_from_card_ids(group_ids, indexed_hand)
		if play_state.is_empty():
			continue
		return {
			"type": "play",
			"card_ids": play_state.get("card_ids", []).duplicate(),
			"play_state": play_state,
			"display_text": String(play_state.get("display_text", ""))
		}

	var joker_ids: Array = []
	for card_data in indexed_hand:
		var rank = String(card_data["rank"])
		if _is_joker_rank(rank):
			joker_ids.append(card_data["id"])

	if joker_ids.is_empty():
		return {}

	var joker_play := _build_play_state_from_card_ids(joker_ids, indexed_hand)
	if joker_play.is_empty():
		return {}

	return {
		"type": "play",
		"card_ids": joker_play.get("card_ids", []).duplicate(),
		"play_state": joker_play,
		"display_text": String(joker_play.get("display_text", ""))
	}


func _on_hint_button_pressed() -> void:
	if current_turn_index != HUMAN_PLAYER_INDEX:
		return
	var suggestions := _get_hint_suggestions()
	if suggestions.is_empty():
		if not last_play.is_empty():
			_on_pass_button_pressed()
			status_label.text = "提示：当前无牌可压，已为你选择不要。"
			return
		status_label.text = "当前没有符合规则的可出牌型。"
		return

	if suggestions.size() == 1:
		if hint_cycle_index == 0:
			status_label.text = "提示：没有更大的牌了。"
		else:
			status_label.text = "提示：最小可出牌型为 %s" % String(suggestions[0].get("display_text", ""))
		hint_cycle_index = 0
		selected_card_ids = suggestions[0].get("card_ids", []).duplicate()
		selected_card_ids.sort()
		_refresh_selection_state()
		return

	hint_cycle_index = (hint_cycle_index + 1) % suggestions.size()
	var suggestion: Dictionary = suggestions[hint_cycle_index]
	selected_card_ids = suggestion.get("card_ids", []).duplicate()
	selected_card_ids.sort()
	_refresh_selection_state()
	if hint_cycle_index == 0:
		status_label.text = "提示：最小可出牌型为 %s" % String(suggestion.get("display_text", ""))
	else:
		status_label.text = "提示：更大的可出牌型为 %s" % String(suggestion.get("display_text", ""))


func _render_play_cards(container: HBoxContainer, cards: Array, scale_value: float, alignment: int = 1, show_pass: bool = false, count_side: String = "right") -> void:
	if container == null:
		return
	var render_signature := _build_play_render_signature(cards, scale_value, alignment, show_pass, count_side)
	if String(container.get_meta("render_signature", "")) == render_signature:
		return
	container.set_meta("render_signature", render_signature)

	for child in container.get_children():
		child.queue_free()
	container.alignment = alignment
	container.add_theme_constant_override("separation", 8)

	if cards.is_empty() and not show_pass:
		return

	if show_pass:
		var pass_label := Label.new()
		pass_label.text = "不要"
		pass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pass_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pass_label.add_theme_font_size_override("font_size", 22)
		pass_label.modulate = Color(0.94, 0.94, 0.94, 0.92)
		container.add_child(pass_label)
		return

	var visible_cards := cards
	var total_count := cards.size()
	visible_cards = _sort_visible_play_cards(visible_cards)

	var card_holder := HBoxContainer.new()
	card_holder.add_theme_constant_override("separation", _get_play_area_separation())
	card_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if total_count > 1 and count_side == "left":
		container.add_child(_build_play_overflow_label(total_count))

	for card in visible_cards:
		var card_view := CARD_VIEW_SCRIPT.new()
		card_view.setup("opponent_%s" % String(card), String(card))
		card_view.set_disabled(true, false)
		card_view.scale = Vector2(scale_value, scale_value)
		card_holder.add_child(card_view)

	container.add_child(card_holder)

	if total_count > 1 and count_side != "left":
		container.add_child(_build_play_overflow_label(total_count))


func _build_play_overflow_label(overflow_count: int) -> Label:
	var overflow_label := Label.new()
	overflow_label.text = "%d张" % overflow_count
	overflow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overflow_label.add_theme_font_size_override("font_size", 20)
	overflow_label.modulate = Color(0.94, 0.94, 0.94, 0.92)
	return overflow_label


func _build_play_render_signature(cards: Array, scale_value: float, alignment: int, show_pass: bool, count_side: String) -> String:
	var parts: Array = [str(scale_value), str(alignment), str(show_pass), count_side]
	for card in cards:
		parts.append(String(card))
	return "|".join(parts)


func _sort_visible_play_cards(cards: Array) -> Array:
	var regular_cards: Array = []
	var special_cards: Array = []

	for card_variant in cards:
		var card_text := String(card_variant)
		var rank := _get_rank(card_text)
		if _is_joker_rank(rank):
			special_cards.append(card_text)
		else:
			regular_cards.append(card_text)

	var sorted_cards: Array = []
	sorted_cards.append_array(regular_cards)
	sorted_cards.append_array(special_cards)
	return sorted_cards


func _enumerate_candidate_plays(player_index: int, indexed_hand: Array, groups: Array) -> Array:
	var candidates: Array = []
	var joker_ids := _get_special_card_ids(indexed_hand)
	var required_count := 0
	if not last_play.is_empty():
		required_count = int(last_play.get("card_count", 0))

	for group in groups:
		var rank = String(group[0]["rank"])
		if _is_joker_rank(rank):
			continue
		if rank == "3" and not _can_play_three_for_player(player_index):
			continue

		var group_ids: Array = []
		for card_data in group:
			group_ids.append(card_data["id"])

		for base_count in range(1, group_ids.size() + 1):
			var base_ids := _take_visible_rank_ids(group_ids, base_count)
			if required_count > 0:
				var needed_jokers := required_count - base_count
				if needed_jokers < 0 or needed_jokers > joker_ids.size():
					continue
				var exact_combos := _build_special_id_combinations(joker_ids, needed_jokers)
				for exact_combo_variant in exact_combos:
					var exact_combo: Array = exact_combo_variant
					var exact_ids := base_ids.duplicate()
					exact_ids.append_array(exact_combo)
					var exact_play := _build_play_state_from_card_ids(exact_ids, indexed_hand)
					if not exact_play.is_empty():
						candidates.append(exact_play)
			else:
				for joker_count in range(joker_ids.size() + 1):
					var joker_combos := _build_special_id_combinations(joker_ids, joker_count)
					for combo_variant in joker_combos:
						var combo: Array = combo_variant
						var combo_ids := base_ids.duplicate()
						combo_ids.append_array(combo)
						var combo_play := _build_play_state_from_card_ids(combo_ids, indexed_hand)
						if not combo_play.is_empty():
							candidates.append(combo_play)

	if required_count > 0:
		if joker_ids.size() >= required_count:
			var pure_joker_combos := _build_special_id_combinations(joker_ids, required_count)
			for pure_combo_variant in pure_joker_combos:
				var pure_combo: Array = pure_combo_variant
				var pure_joker_play := _build_play_state_from_card_ids(pure_combo, indexed_hand)
				if not pure_joker_play.is_empty():
					candidates.append(pure_joker_play)
	else:
		for joker_count in range(1, joker_ids.size() + 1):
			var pure_joker_combos := _build_special_id_combinations(joker_ids, joker_count)
			for pure_combo_variant in pure_joker_combos:
				var pure_combo: Array = pure_combo_variant
				var pure_joker_play := _build_play_state_from_card_ids(pure_combo, indexed_hand)
				if not pure_joker_play.is_empty():
					candidates.append(pure_joker_play)

	return candidates


func _take_visible_rank_ids(group_ids: Array, count: int) -> Array:
	if count >= group_ids.size():
		return group_ids.duplicate()
	return group_ids.slice(group_ids.size() - count, group_ids.size())


func _needs_extra_gap_between_ranks(current_rank: String, next_rank: String) -> bool:
	return false


func _is_top_special_rank(rank: String) -> bool:
	return rank == "4" or rank == "大王" or rank == "小王"


func _get_hand_group_separation() -> int:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var settings := (main_loop as SceneTree).root.get_node_or_null("UserSettings")
		if settings != null:
			return int(settings.get_hand_group_separation())
	return -44


func _get_hand_rank_gap() -> int:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var settings := (main_loop as SceneTree).root.get_node_or_null("UserSettings")
		if settings != null:
			return int(settings.get_hand_rank_gap())
	return 0


func _get_play_area_separation() -> int:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var settings := (main_loop as SceneTree).root.get_node_or_null("UserSettings")
		if settings != null:
			return int(settings.get_play_area_separation())
	return -44


func _get_special_card_ids(indexed_hand: Array) -> Array:
	var special_cards: Array = []
	for card_data_variant in indexed_hand:
		var card_data: Dictionary = card_data_variant
		var rank = String(card_data["rank"])
		if _is_joker_rank(rank):
			special_cards.append(card_data)

	special_cards.sort_custom(Callable(self, "_sort_special_cards_for_fill"))

	var ids: Array = []
	for card_data_variant in special_cards:
		var card_data: Dictionary = card_data_variant
		ids.append(card_data["id"])
	return ids


func _sort_special_cards_for_fill(a: Dictionary, b: Dictionary) -> bool:
	return _get_rank_order(String(a["rank"])) > _get_rank_order(String(b["rank"]))


func _build_special_id_combinations(ids: Array, target_count: int, start_index: int = 0, current: Array = []) -> Array:
	if target_count == 0:
		return [current.duplicate()]

	var results: Array = []
	for index in range(start_index, ids.size()):
		current.append(ids[index])
		var nested_results := _build_special_id_combinations(ids, target_count - 1, index + 1, current)
		for nested_variant in nested_results:
			results.append(nested_variant)
		current.pop_back()
	return results


func _is_play_weaker(a: Dictionary, b: Dictionary) -> bool:
	var count_a := int(a.get("card_count", 0))
	var count_b := int(b.get("card_count", 0))
	if count_a != count_b:
		return count_a < count_b

	var orders_a: Array = a.get("card_orders", [])
	var orders_b: Array = b.get("card_orders", [])
	for index in range(min(orders_a.size(), orders_b.size())):
		var order_a := int(orders_a[index])
		var order_b := int(orders_b[index])
		if order_a != order_b:
			return order_a > order_b

	return false


func _reset_hint_cycle() -> void:
	hint_cycle_signature = ""
	hint_cycle_options.clear()
	hint_cycle_index = -1


func _get_hint_suggestions() -> Array:
	var signature := _build_hint_signature()
	if signature == hint_cycle_signature and not hint_cycle_options.is_empty():
		return hint_cycle_options

	hint_cycle_signature = signature
	hint_cycle_index = -1
	hint_cycle_options = _build_hint_suggestions()
	return hint_cycle_options


func _build_hint_signature() -> String:
	var hand_cards: Array = []
	for card in players[HUMAN_PLAYER_INDEX]["cards"]:
		hand_cards.append(String(card))

	var last_orders_text := ""
	if not last_play.is_empty():
		var last_orders: Array = last_play.get("card_orders", [])
		var order_parts: Array = []
		for order in last_orders:
			order_parts.append(str(order))
		last_orders_text = ",".join(order_parts)

	return "%d|%s|%s" % [current_turn_index, "|".join(hand_cards), last_orders_text]


func _build_hint_suggestions() -> Array:
	if last_play.is_empty():
		var lead_suggestion := _find_min_play_for_player(HUMAN_PLAYER_INDEX)
		if lead_suggestion.is_empty():
			return []
		return [lead_suggestion]

	var hand = players[HUMAN_PLAYER_INDEX]["cards"]
	var indexed_hand = _build_indexed_hand(hand)
	var groups = _group_cards_by_rank(indexed_hand)
	var candidate_plays := _enumerate_candidate_plays(HUMAN_PLAYER_INDEX, indexed_hand, groups)
	var legal_suggestions: Array = []
	var seen_keys: Dictionary = {}

	for candidate_variant in candidate_plays:
		var candidate: Dictionary = candidate_variant
		if not _can_beat_last_play(candidate):
			continue
		var card_ids: Array = candidate.get("card_ids", [])
		var key_parts: Array = []
		for card_id in card_ids:
			key_parts.append(String(card_id))
		key_parts.sort()
		var key := "|".join(key_parts)
		if seen_keys.has(key):
			continue
		seen_keys[key] = true
		legal_suggestions.append(
			{
				"type": "play",
				"card_ids": card_ids.duplicate(),
				"play_state": candidate,
				"display_text": String(candidate.get("display_text", ""))
			}
		)

	legal_suggestions.sort_custom(Callable(self, "_sort_hint_suggestions"))
	return legal_suggestions


func _sort_hint_suggestions(a: Dictionary, b: Dictionary) -> bool:
	return _is_play_weaker(a.get("play_state", {}), b.get("play_state", {}))


func _get_user_name() -> String:
	var settings := get_node_or_null("/root/UserSettings")
	if settings == null:
		return "你"
	return String(settings.get_user_name())


func _start_turn_countdown() -> void:
	turn_timeout_triggered = false
	turn_deadline_msec = Time.get_ticks_msec() + 30000
	_update_turn_labels()


func _get_turn_countdown_seconds() -> int:
	if turn_deadline_msec <= 0:
		return 30
	var remaining_msec := maxi(turn_deadline_msec - Time.get_ticks_msec(), 0)
	return maxi(int(ceil(float(remaining_msec) / 1000.0)), 0)


func _update_turn_labels() -> void:
	if is_instance_valid(player_countdown_label):
		player_countdown_label.text = _get_countdown_text(HUMAN_PLAYER_INDEX)
	for slot in opponent_slots:
		var player_index := int(slot["player_index"])
		slot["turn_label"].text = ""
		slot["countdown_label"].text = _get_countdown_text(player_index)


func _handle_turn_timeout() -> void:
	if current_turn_index != HUMAN_PLAYER_INDEX:
		_execute_ai_pass()
		return
	if not last_play.is_empty() and int(last_play.get("player_index", -1)) != HUMAN_PLAYER_INDEX:
		_on_pass_button_pressed()
		status_label.text = "%s 超时，已自动不要。" % _format_player_name(HUMAN_PLAYER_INDEX)
		return

	var suggestions := _get_hint_suggestions()
	if suggestions.is_empty():
		status_label.text = "%s 超时，但当前没有可自动执行的操作。" % _format_player_name(HUMAN_PLAYER_INDEX)
		_start_turn_countdown()
		return

	selected_card_ids = suggestions[0].get("card_ids", []).duplicate()
	selected_card_ids.sort()
	_refresh_selection_state()
	_on_play_button_pressed()
	status_label.text = "%s 超时，已自动出最小可出牌。" % _format_player_name(HUMAN_PLAYER_INDEX)
