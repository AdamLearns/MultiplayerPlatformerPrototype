extends Node2D

func _ready() -> void:
	$MultiplayerSpawner.set_spawn_function(Callable(self, "_spawn_player"))
	set_physics_process(multiplayer.is_server())

func _spawn_player(data: Dictionary) -> Node:
	var id: int = data["id"]
	var player_position: Vector2 = data["position"]
	var player: Node = preload ("res://scenes/Player.tscn").instantiate()
	player.init(id)
	print("Adding player %s to the scene" % [id])
	player.name = "Player #%s" % id
	player.position = player_position
	return player

func add_player(id: int) -> Node:
	var player_position := Vector2(randi() % 1000, randi() % 500)
	return $MultiplayerSpawner.spawn({"id": id, "position": player_position})

func remove_player(id: int) -> void:
	var player := $SpawnedPlayers.get_node_or_null("Player #%s"% id)
	if player:
		player.queue_free()
