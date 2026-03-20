extends Control

const PLAYER_COUNT := 5
const GAME_SCENE := "res://scenes/main_menu.tscn"
const CARD_VIEW_SCRIPT := preload("res://scripts/card_view.gd")
const EMPEROR_CARD := "皇帝牌"
const HUMAN_PLAYER_INDEX := 0

@onready var status_label: Label = %StatusLabel
@onready var summary_text: Label = %SummaryText
@onready var center_hint: Label = %CenterHint
@onready var current_turn_label: Label = %CurrentTurnLabel
@onready var emperor_label: Label = %EmperorLabel
@onready var last_play_label: Label = %LastPlayLabel
@onready var player_label: Label = %PlayerLabel
@onready var hand_meta: Label = %HandMeta
@onready var play_button: Button = %PlayButton
@onready var hint_button: Button = %HintButton
@onready var pass_button: Button = %PassButton
@onready var player_play_cards: HBoxContainer = %PlayerPlayCards
@onready var top_hand_row: HBoxContainer = $Margin/Root/PlayerHandPanel/HandVBox/HandRows/TopHandRow
@onready var bottom_hand_row: HBoxContainer = %BottomHandRow

const CARD_ORDER := {
	"大王": 0,
	"小王": 1,
	"2": 2,
	"A": 3,
	"K": 4,
	"Q": 5,
	"J": 6,
	"10": 7,
	"9": 8,
	"8": 9,
	"7": 10,
	"6": 11,
	"5": 12,
	"4": 13,
	"3": 14
}

const SUIT_ORDER := {
	"♠": 0,
	"♥": 1,
	"♣": 2,
	"♦": 3
}

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


func _ready() -> void:
	_bind_player_nodes()
	_strip_opponent_panel_backgrounds()
	_deal_cards()


func _bind_player_nodes() -> void:
	players = [
		{
			"name": "你",
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
			"name_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Info/Name,
			"avatar_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Info/Avatar,
			"count_label": $Margin/Root/TableArea/RightColumn/Opponent5/Row/Info/Count,
			"play_container": $Margin/Root/TableArea/RightColumn/Opponent5/Row/PlayRow
		},
		{
			"player_index": 2,
			"panel": $Margin/Root/TableArea/RightColumn/Opponent4,
			"name_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Info/Name,
			"avatar_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Info/Avatar,
			"count_label": $Margin/Root/TableArea/RightColumn/Opponent4/Row/Info/Count,
			"play_container": $Margin/Root/TableArea/RightColumn/Opponent4/Row/PlayRow
		},
		{
			"player_index": 3,
			"panel": $Margin/Root/TableArea/LeftColumn/Opponent2,
			"name_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Info/Name,
			"avatar_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Info/Avatar,
			"count_label": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/Info/Count,
			"play_container": $Margin/Root/TableArea/LeftColumn/Opponent2/Row/PlayRow
		},
		{
			"player_index": 4,
			"panel": $Margin/Root/TableArea/LeftColumn/Opponent3,
			"name_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Info/Name,
			"avatar_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Info/Avatar,
			"count_label": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/Info/Count,
			"play_container": $Margin/Root/TableArea/LeftColumn/Opponent3/Row/PlayRow
		}
	]


func _deal_cards() -> void:
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

	_assign_emperor()
	current_turn_index = emperor_player_index
	_refresh_ui(deck.size() + threes.size())


func _refresh_ui(total_cards: int) -> void:
	var counts: Array = []
	var current_player = players[current_turn_index]
	var human_player = players[HUMAN_PLAYER_INDEX]
	var current_hand = human_player["cards"]

	for index in range(players.size()):
		var player = players[index]
		var hand = player["cards"]
		counts.append("%s %d 张" % [player["name"], hand.size()])

	_update_opponent_slots()
	_render_play_cards(player_play_cards, human_player.get("shown_play", []), 0.74, 1)

	if last_play.is_empty():
		status_label.text = "已将 %d 张牌发给 %d 名玩家，其中 3 共 5 张且每人 1 张。" % [total_cards, PLAYER_COUNT]
	summary_text.text = "发牌结果：%s" % " | ".join(counts)
	center_hint.text = "下方始终展示你的手牌，其余四名为 AI。"
	current_turn_label.text = "当前出牌：%s" % _format_player_name(current_turn_index)
	emperor_label.text = "皇帝：%s" % _get_emperor_display_name()
	last_play_label.text = _get_last_play_text()
	player_label.text = "你的手牌：%s" % _format_player_name(HUMAN_PLAYER_INDEX)
	hand_meta.text = "手牌数：%d" % current_hand.size()
	_render_current_hand(current_hand)
	_update_action_buttons()
	_maybe_run_ai_turn()


func _update_opponent_slots() -> void:
	for slot in opponent_slots:
		var player_index = int(slot["player_index"])
		var player = players[player_index]
		slot["count_label"].text = "手牌数：%d" % player["cards"].size()
		slot["name_label"].text = _format_player_name(player_index)
		slot["avatar_label"].text = _format_player_avatar(player_index)
		_render_play_cards(
			slot["play_container"],
			player.get("shown_play", []),
			0.62,
			slot["play_container"].alignment,
			bool(player.get("passed", false))
		)


func _strip_opponent_panel_backgrounds() -> void:
	var empty_style := StyleBoxEmpty.new()
	for slot in opponent_slots:
		var panel: PanelContainer = slot["panel"]
		panel.add_theme_stylebox_override("panel", empty_style)


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
	for group in groups:
		var rank_group := HBoxContainer.new()
		rank_group.add_theme_constant_override("separation", -42)
		row.add_child(rank_group)

		for card_data in group:
			var card_view := CARD_VIEW_SCRIPT.new()
			var card_id = card_data["id"]
			var card_text = card_data["text"]
			var rank = card_data["rank"]
			card_view.setup(card_id, card_text)
			card_view.card_pressed.connect(_on_card_pressed)
			card_view.set_selected(selected_card_ids.has(card_id))
			card_view.set_disabled(not _can_select_rank(rank, card_id))
			rank_group.add_child(card_view)
			hand_card_lookup[card_id] = card_data


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

	var target_top_count := int(ceil(total_cards / 2.0))
	var current_top_count := 0

	for index in range(groups.size()):
		var group: Array = groups[index]
		if current_top_count < target_top_count:
			top_groups.append(group)
			current_top_count += group.size()
		else:
			bottom_groups.append(group)

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
	var clicked_rank := _get_rank(card_text)
	if not _can_select_rank(clicked_rank, card_id):
		return

	if selected_card_ids.has(card_id):
		selected_card_ids.erase(card_id)
	else:
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
	if current_turn_index != HUMAN_PLAYER_INDEX:
		return false
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
	return rank == "大王" or rank == "小王"


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
	var can_show_play := is_human_turn and not selected_card_ids.is_empty()
	var can_pass := is_human_turn and not last_play.is_empty() and int(last_play.get("player_index", -1)) != HUMAN_PLAYER_INDEX
	play_button.visible = can_show_play
	hint_button.visible = is_human_turn
	pass_button.visible = can_pass


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


func _assign_emperor() -> void:
	for index in range(players.size()):
		var cards = players[index]["cards"]
		for card in cards:
			if String(card) == EMPEROR_CARD:
				emperor_player_index = index
				players[index]["role"] = "皇帝"
				return


func _format_player_name(player_index: int) -> String:
	var player = players[player_index]
	if player.get("role", "") == "皇帝":
		return "%s · 皇帝" % player["name"]
	return player["name"]


func _format_player_avatar(player_index: int) -> String:
	var player = players[player_index]
	var base_avatar := "🙂"
	if player_index == 1:
		base_avatar = "🙂"
	elif player_index == 2:
		base_avatar = "😎"
	elif player_index == 3:
		base_avatar = "🤖"
	elif player_index == 4:
		base_avatar = "👽"
	if player.get("role", "") == "皇帝":
		return "👑"
	return base_avatar


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
	await get_tree().create_timer(0.6).timeout
	if token != ai_turn_token:
		return
	if current_turn_index == HUMAN_PLAYER_INDEX:
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
	selected_card_ids.clear()
	selected_anchor_rank = ""

	var action_text := "%s 出牌：%s" % [_format_player_name(current_turn_index), String(last_play.get("display_text", ""))]
	if current_cards.is_empty():
		last_play = {}
		_clear_displayed_plays()
		_refresh_ui(_get_total_card_count())
		status_label.text = "%s 获胜。" % _format_player_name(current_turn_index)
		return

	_advance_turn()
	_refresh_ui(_get_total_card_count())
	status_label.text = action_text


func _execute_ai_pass() -> void:
	consecutive_passes += 1
	selected_card_ids.clear()
	selected_anchor_rank = ""
	players[current_turn_index]["shown_play"] = []
	players[current_turn_index]["passed"] = true
	var pass_text := "%s 不要。" % _format_player_name(current_turn_index)
	if consecutive_passes >= PLAYER_COUNT - 1:
		consecutive_passes = 0
		current_turn_index = int(last_play.get("player_index", current_turn_index))
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
	var suggestion := _find_min_play_for_player(HUMAN_PLAYER_INDEX)
	if suggestion.is_empty():
		if not last_play.is_empty():
			_on_pass_button_pressed()
			status_label.text = "提示：当前无牌可压，已为你选择不要。"
			return
		status_label.text = "当前没有符合规则的可出牌型。"
		return
	selected_card_ids = suggestion.get("card_ids", []).duplicate()
	selected_card_ids.sort()
	_refresh_selection_state()
	status_label.text = "提示：最小可出牌型为 %s" % String(suggestion.get("display_text", ""))


func _render_play_cards(container: HBoxContainer, cards: Array, scale_value: float, alignment: int = 1, show_pass: bool = false) -> void:
	for child in container.get_children():
		child.queue_free()
	container.alignment = alignment
	if show_pass:
		var pass_label := Label.new()
		pass_label.text = "不要"
		pass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pass_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pass_label.add_theme_font_size_override("font_size", 22)
		pass_label.modulate = Color(0.94, 0.94, 0.94, 0.92)
		container.add_child(pass_label)
		return

	for card in cards:
		var card_view := CARD_VIEW_SCRIPT.new()
		card_view.setup("opponent_%s" % String(card), String(card))
		card_view.set_disabled(true, false)
		card_view.scale = Vector2(scale_value, scale_value)
		container.add_child(card_view)


func _enumerate_candidate_plays(player_index: int, indexed_hand: Array, groups: Array) -> Array:
	var candidates: Array = []
	var joker_ids: Array = []
	var required_count := 0
	if not last_play.is_empty():
		required_count = int(last_play.get("card_count", 0))

	for card_data in indexed_hand:
		var rank = String(card_data["rank"])
		if _is_joker_rank(rank):
			joker_ids.append(card_data["id"])

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
			var base_ids := group_ids.slice(0, base_count)
			if required_count > 0:
				var needed_jokers := required_count - base_count
				if needed_jokers < 0 or needed_jokers > joker_ids.size():
					continue
				var exact_ids := base_ids.duplicate()
				exact_ids.append_array(joker_ids.slice(0, needed_jokers))
				var exact_play := _build_play_state_from_card_ids(exact_ids, indexed_hand)
				if not exact_play.is_empty():
					candidates.append(exact_play)
			else:
				for joker_count in range(joker_ids.size() + 1):
					var combo_ids := base_ids.duplicate()
					combo_ids.append_array(joker_ids.slice(0, joker_count))
					var combo_play := _build_play_state_from_card_ids(combo_ids, indexed_hand)
					if not combo_play.is_empty():
						candidates.append(combo_play)

	if required_count > 0:
		if joker_ids.size() >= required_count:
			var pure_joker_ids := joker_ids.slice(0, required_count)
			var pure_joker_play := _build_play_state_from_card_ids(pure_joker_ids, indexed_hand)
			if not pure_joker_play.is_empty():
				candidates.append(pure_joker_play)
	else:
		for joker_count in range(1, joker_ids.size() + 1):
			var pure_joker_ids := joker_ids.slice(0, joker_count)
			var pure_joker_play := _build_play_state_from_card_ids(pure_joker_ids, indexed_hand)
			if not pure_joker_play.is_empty():
				candidates.append(pure_joker_play)

	return candidates


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
