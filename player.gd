extends CharacterBody3D
class_name Player

const GRAVITY = 10
const SPEED = 2
const JUMP_STRENGTH = 5

const POSITION_CHECK_PERIOD = 0.2

func _ready() -> void:
	if get_parent() is Map:
		_check_position()

func _process(delta: float) -> void:
	var previous_velocity : Vector3 = velocity
	if !is_on_floor():
		velocity -= basis.y * GRAVITY * delta
	if Input.is_action_just_pressed("go_left"):
		velocity -= basis.x * SPEED
	if Input.is_action_just_pressed("go_right"):
		velocity += basis.x * SPEED
	if Input.is_action_just_pressed("jump"):
		velocity += basis.y * JUMP_STRENGTH
	
	_update_facing_direction()
	
	move_and_slide()
	
	_update_animation(previous_velocity)
	


# Making the player face the right direction - to be optimized
func _update_facing_direction():
	if (Vector3.RIGHT * basis * velocity).x < 0:
		$AnimatedSprite3D.flip_h = true
	elif (Vector3.RIGHT * basis * velocity).x > 0:
		$AnimatedSprite3D.flip_h = false

func _update_animation(previous_velocity : Vector3):
	if previous_velocity == Vector3.ZERO and velocity != Vector3.ZERO:
		$AnimatedSprite3D.play("walk")
	elif previous_velocity != Vector3.ZERO and velocity == Vector3.ZERO:
		$AnimatedSprite3D.play("idle")

func _check_position():
	var map : Map = get_parent()
	get_tree().create_timer(POSITION_CHECK_PERIOD).timeout.connect(_check_position)
	
	var future_cell_position : Vector3i = map.local_to_map(position + map.cell_size * velocity.normalized())
	
	var future_mesh_id : int = map.get_cell_item(future_cell_position)
	
	# if not is on floor - look for floor
	# if is on floor - look if view obstructed, keep on floor
	const EMPTY_CELL_ID : int = map.INVALID_CELL_ITEM
	
	# might look for ceiling to hit when done like that...
	if !is_on_floor() and future_mesh_id == EMPTY_CELL_ID:
		print_debug("Looking for ground to fall on")
		#var correct_cell_position : Vector3i = map.find_cell_in_row(map.mesh_library.find_item_by_name("Wall"))
		#if correct_cell_position:
			#move_to_cell(correct_cell_position)
	
	if is_on_floor():
		if !map.cell_in_view(future_cell_position):
			print_debug("Moving out of view")
		if map.get_cell_item(future_cell_position + Vector3i(Vector3.DOWN * basis)):
			print_debug("Will fall")

func move_to_cell(cell_position : Vector3i):
	pass

func stop_movement():
	velocity = Vector3.ZERO

func update_rotation(new_basis : Basis):
	basis = new_basis
