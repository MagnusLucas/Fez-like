extends CharacterBody3D
class_name Player

const GRAVITY = 10
const SPEED = 2
const JUMP_STRENGTH = 5

const POSITION_CHECK_PERIOD = 0.2

var can_move : bool = true
var map : Map
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


func _ready() -> void:
	if get_parent() is Map:
		map = get_parent()
		_check_position()

func _process(delta: float) -> void:
	var previous_velocity : Vector3 = velocity
	_move(delta)
	_update_animation(previous_velocity)
	_update_visibility()

func _move(delta: float) -> void:
	if can_move:
		if !is_on_floor():
			velocity -= basis.y * GRAVITY * delta
		_handle_input()
	_update_facing_direction()
	move_and_slide()

func _handle_input() -> void:
	if Input.is_action_just_pressed("go_left"):
		velocity -= basis.x * SPEED
	if Input.is_action_just_pressed("go_right"):
		velocity += basis.x * SPEED
	if Input.is_action_just_pressed("jump"):
		velocity += basis.y * JUMP_STRENGTH

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_check_position()

# Making the player face the right direction - to be optimized
func _update_facing_direction() -> void:
	if (Vector3.RIGHT * basis * velocity).x < 0:
		sprite.flip_h = true
	elif (Vector3.RIGHT * basis * velocity).x > 0:
		sprite.flip_h = false

func _update_animation(previous_velocity : Vector3) -> void:
	if previous_velocity == Vector3.ZERO and velocity != Vector3.ZERO:
		sprite.play("walk")
	elif previous_velocity != Vector3.ZERO and velocity == Vector3.ZERO:
		sprite.play("idle")

func _is_falling() -> bool:
	if is_on_floor():
		return false
	return (Vector3.UP * basis * velocity).y < 0

func _is_raising() -> bool:
	if is_on_floor():
		return false
	return (Vector3.UP * basis * velocity).y > 0

func _update_visibility() -> void:
	if !map.cell_in_view(map.local_to_map(position)):
		sprite.modulate = Color("444444")
	else:
		sprite.modulate = Color.WHITE
	

func _check_position() -> void:
	get_tree().create_timer(POSITION_CHECK_PERIOD).timeout.connect(_check_position)
	
	var position_offset : Vector3 = $CollisionShape3D.get_point_position(PointCollision.Position.LOWEST) * basis
	
	# This might be problematic - can go diagonally and not check vertical collisions
	
	# Update: This actually is the problem xD
	var future_cell_position : Vector3i = map.local_to_map(position + position_offset + 
			map.cell_size * velocity.normalized())
	var future_mesh_id : int = map.get_cell_item(future_cell_position)
	
	
	# if not is on floor - look for floor
	# if is on floor - look if view obstructed, keep on floor
	const EMPTY_CELL_ID : int = map.INVALID_CELL_ITEM
	
	# Handling falling
	if _is_falling() and future_mesh_id == EMPTY_CELL_ID:
		print("Looking for ground to fall on")
		var found_coordinates = map.find_ground(map.local_to_map(
				position + position_offset))
		if found_coordinates != null:
			print(map.local_to_map(position + position_offset), future_cell_position )
			move_to_cell(found_coordinates)
	
	elif _is_raising() and future_mesh_id != EMPTY_CELL_ID:
		print("Bonk!")
	
	#if is_on_floor():
		#if map.get_cell_item(future_cell_position + Vector3i(Vector3.DOWN * basis)):
			#print_debug("Will fall")

func align_in_cell(axis : Vector3) -> void:
	var cell_position = map.local_to_map(position)
	var in_cell_offset : Vector3 = position - map.map_to_local(cell_position)
	var fixed_cell_offset : Vector3 = in_cell_offset * (Vector3.ONE - abs(axis))
	position = map.map_to_local(cell_position) + fixed_cell_offset

func move_to_cell(destination : Vector3i) -> void:
	print("Move to: ", destination)
	var cell_position = map.local_to_map(position)
	var in_cell_offset : Vector3 = position - map.map_to_local(cell_position)
	position = map.map_to_local(destination) + in_cell_offset

func handle_camera_rotation_started() -> void:
	velocity = Vector3.ZERO
	can_move = false
	
	sprite.pause()

func handle_camera_rotation_finished(new_basis : Basis) -> void:
	basis = new_basis
	can_move = true
	
	sprite.play()
	
	align_in_cell(Vector3.FORWARD * basis)
