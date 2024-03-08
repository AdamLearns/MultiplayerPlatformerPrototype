extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -800.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var sync_pos := Vector2.ZERO

func init(owner_id: int) -> void:
	set_multiplayer_authority(owner_id)
	$IDLabel.text = str(owner_id)

func _physics_process(delta: float) -> void:
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		_physics_process_authoritative(delta)
	else:
		_physics_process_nonauthoritative(delta)

func _physics_process_nonauthoritative(_delta: float) -> void:
	global_position = global_position.lerp(sync_pos, 0.5)

func _physics_process_authoritative(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("ui_home"):
		position = Vector2(randi() % 1000, 0)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction: float = Input.get_axis("ui_left", "ui_right")

	if Input.get_axis("ui_up", "ui_down"):
		velocity.y += 2 * gravity * delta

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	sync_pos = global_position
