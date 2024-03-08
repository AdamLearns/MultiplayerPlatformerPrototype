extends Node2D

var num_nodes_to_add := 0
var num_nodes_added := 0

func _ready() -> void:
	set_physics_process(multiplayer.is_server())

func _physics_process(_delta: float) -> void:
	if num_nodes_to_add > 0:
		_add_node()
		num_nodes_to_add -= 1

func _add_node() -> void:
	var spawnable_scene: Node = preload ("res://scenes/Spawnable.tscn").instantiate()
	spawnable_scene.position = Vector2(randi() % 1000, randi() % 500)
	num_nodes_added += 1
	spawnable_scene.name = "Spawnable #%s" % num_nodes_added
	print("Adding %s to the scene at %s" % [spawnable_scene.name, spawnable_scene.position])
	$SpawnedIcons.add_child(spawnable_scene)
