extends Node

signal lobby_changed(players: Array)
signal match_state_received(snapshot: Dictionary)
signal connection_ready()
signal connection_failed(message: String)
signal disconnected(message: String)
signal client_action_requested(peer_id: int, action: Dictionary)
signal peer_dropped(peer_id: int)

const MODE_OFFLINE := "offline"
const MODE_HOST := "host"
const MODE_CLIENT := "client"
const DEFAULT_PORT := 7000
const MAX_REMOTE_CLIENTS := 4
var mode := MODE_OFFLINE
var local_player_name := "你"
var lobby_players: Array = []
var match_started := false
var latest_match_snapshot: Dictionary = {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_network_game() -> bool:
	return mode != MODE_OFFLINE


func is_host() -> bool:
	return mode == MODE_HOST


func get_lobby_players() -> Array:
	return lobby_players.duplicate(true)


func get_local_peer_id() -> int:
	return multiplayer.get_unique_id()


func get_local_player_name() -> String:
	return local_player_name


func is_match_started() -> bool:
	return match_started


func get_latest_match_snapshot() -> Dictionary:
	return latest_match_snapshot.duplicate(true)


func host_game(player_name: String, port: int = DEFAULT_PORT) -> int:
	_reset_session_state()
	local_player_name = _sanitize_player_name(player_name)
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_REMOTE_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = MODE_HOST
	match_started = false
	latest_match_snapshot.clear()
	lobby_players = [
		{
			"peer_id": multiplayer.get_unique_id(),
			"name": local_player_name
		}
	]
	lobby_changed.emit(get_lobby_players())
	connection_ready.emit()
	return OK


func join_game(player_name: String, address: String, port: int = DEFAULT_PORT) -> int:
	_reset_session_state()
	local_player_name = _sanitize_player_name(player_name)
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = MODE_CLIENT
	match_started = false
	latest_match_snapshot.clear()
	lobby_players.clear()
	return OK


func leave_session() -> void:
	_reset_session_state()


func set_match_started(value: bool) -> void:
	match_started = value
	if not value:
		latest_match_snapshot.clear()
	if multiplayer.is_server():
		_broadcast_lobby()


func submit_action(action: Dictionary) -> void:
	if mode == MODE_OFFLINE:
		return
	if mode == MODE_HOST:
		client_action_requested.emit(multiplayer.get_unique_id(), action.duplicate(true))
		return
	rpc_id(1, "_server_submit_action", action.duplicate(true))


func publish_match_states(states_by_peer: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	for peer_key in states_by_peer.keys():
		var peer_id := int(peer_key)
		var snapshot: Dictionary = states_by_peer[peer_key]
		if peer_id != multiplayer.get_unique_id():
			rpc_id(peer_id, "_client_receive_match_state", snapshot.duplicate(true))


func _reset_session_state() -> void:
	lobby_players.clear()
	match_started = false
	latest_match_snapshot.clear()
	mode = MODE_OFFLINE
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func _sanitize_player_name(player_name: String) -> String:
	var trimmed := player_name.strip_edges()
	return trimmed if trimmed != "" else "你"


func _find_lobby_index(peer_id: int) -> int:
	for index in range(lobby_players.size()):
		if int(lobby_players[index].get("peer_id", -1)) == peer_id:
			return index
	return -1


func _broadcast_lobby() -> void:
	if not multiplayer.is_server():
		return
	var snapshot := {
		"players": get_lobby_players(),
		"match_started": match_started
	}
	lobby_changed.emit(get_lobby_players())
	rpc("_client_receive_lobby", snapshot)


func _on_peer_connected(_peer_id: int) -> void:
	pass


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var index := _find_lobby_index(peer_id)
	if index >= 0:
		lobby_players.remove_at(index)
		_broadcast_lobby()
	if match_started:
		peer_dropped.emit(peer_id)


func _on_connected_to_server() -> void:
	rpc_id(1, "_server_register_player", local_player_name)
	connection_ready.emit()


func _on_connection_failed() -> void:
	var message := "连接服务器失败。"
	connection_failed.emit(message)
	_reset_session_state()


func _on_server_disconnected() -> void:
	var message := "与房主的连接已断开。"
	disconnected.emit(message)
	_reset_session_state()


@rpc("any_peer", "reliable")
func _server_register_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if match_started:
		rpc_id(peer_id, "_client_rejected", "对局已经开始，当前房间不再接受加入。")
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	if lobby_players.size() >= MAX_REMOTE_CLIENTS + 1:
		rpc_id(peer_id, "_client_rejected", "房间已满。")
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	var index := _find_lobby_index(peer_id)
	var player_info := {
		"peer_id": peer_id,
		"name": _sanitize_player_name(player_name)
	}
	if index >= 0:
		lobby_players[index] = player_info
	else:
		lobby_players.append(player_info)
	_broadcast_lobby()


@rpc("any_peer", "reliable")
func _server_submit_action(action: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	client_action_requested.emit(multiplayer.get_remote_sender_id(), action.duplicate(true))


@rpc("authority", "reliable")
func _client_receive_lobby(snapshot: Dictionary) -> void:
	lobby_players = Array(snapshot.get("players", [])).duplicate(true)
	match_started = bool(snapshot.get("match_started", false))
	lobby_changed.emit(get_lobby_players())


@rpc("authority", "reliable")
func _client_receive_match_state(snapshot: Dictionary) -> void:
	match_started = true
	latest_match_snapshot = snapshot.duplicate(true)
	match_state_received.emit(snapshot.duplicate(true))


@rpc("authority", "reliable")
func _client_rejected(message: String) -> void:
	connection_failed.emit(message)
	_reset_session_state()
