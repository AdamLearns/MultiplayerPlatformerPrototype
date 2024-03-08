extends Control

const PORT := 443
const WEBSOCKET_PROTOCOL := "ws://"
const DEFAULT_SERVER_IP := "127.0.0.1"

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players: Dictionary = {}

func _ready() -> void:
	# This signal is emitted on the server and the clients with the newly
	# connected peer's ID on each other peer, and on the new peer multiple times,
	# once with each other peer's ID.
	multiplayer.peer_connected.connect(_on_player_connected)

  # This signal is emitted on the server and the remaining clients when one
  # client disconnects.
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

	# These three signals are only emitted on the clients.
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if MultiplayerFunctions.is_dedicated_server():
		_host_game()
	else:
		_join_game()

func _host_game() -> void:
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	var error: int = peer.create_server(PORT)
	if error:
		print("Error creating server: %s" % error)
		get_tree().quit()
	multiplayer.multiplayer_peer = peer

# We just assign random names for now, not that they're used anywhere. It's just
# a placeholder for when we have "real" information to share.
func _form_player_info() -> Dictionary:
	var possible_names: Array[String] = ["Alice", "Bob", "Carol", "David", "Emily", "Fabien", "Geoffrey", "Hagrid", "Istrid", "Joey"]
	var random_name: String = ArrayFunctions.random_array_element(possible_names)
	return {"name": random_name}

func _add_player(id: int, player_info: Dictionary) -> void:
	players[id] = player_info

func _log_string(text: String) -> void:
	text = str(text)
	print(text)
	$UI/StatusLabel.text = text

func _join_game() -> void:
	_log_string("Joining the server")
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	var address: String = DEFAULT_SERVER_IP
	var error: int = peer.create_client(WEBSOCKET_PROTOCOL + address + ":" + str(PORT))
	if error:
		_log_string("Error creating client: %s. Trying again in a bit." % error)
		await get_tree().create_timer(5.0).timeout
		_join_game()
		return
	multiplayer.multiplayer_peer = peer

func _on_player_connected(id: int) -> void:
	_log_string("Player %s connected. My ID: %s" % [id, multiplayer.get_unique_id()])

	if multiplayer.is_server():
		if !has_node("Game"):
			print("Switching to game scene")
			_switch_to_game_scene()
		$Game.num_nodes_to_add = 3
	else:
		# Register my own player info
		_add_player(multiplayer.get_unique_id(), _form_player_info())

	# Register my player info with the newly connecting player
	_register_player.rpc_id(id, _form_player_info())

func _on_player_disconnected(id: int) -> void:
	_log_string("Player %s disconnected." % id)
	players.erase(id)

@rpc("any_peer", "reliable")
func _register_player(new_player_info: Dictionary) -> void:
	var new_player_id: int = multiplayer.get_remote_sender_id()
	_log_string("Registering player %s as ID %s" % [new_player_info, new_player_id])
	_add_player(new_player_id, new_player_info)

func _on_connected_ok() -> void:
	var peer_id: int = multiplayer.get_unique_id()
	_log_string("Connected to the server with the ID: %s" % peer_id)
	_switch_to_game_scene()

# We can't free the current scene since that would cause us to lose a reference
# to `multiplayer` (which also means that we can't call
# `get_tree().change_scene_to_packed` since that frees the current scene).
# Instead, we just hide the UI elements in the current scene.
func _switch_to_game_scene() -> void:
	$UI.visible = false

	var game_scene: Node = preload ("res://scenes/Game.tscn").instantiate()
	add_child(game_scene)

func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null
	_log_string("Connecting to the server failed. Trying again in a bit.")
	await get_tree().create_timer(5.0).timeout
	_join_game()

func _on_server_disconnected() -> void:
	_log_string("Disconnected from the server. Setting the peer to null.")
	multiplayer.multiplayer_peer = null
	players.clear()

	$UI.visible = true
	if has_node("Game"):
		$Game.queue_free()

	await get_tree().create_timer(5.0).timeout
	_join_game()
