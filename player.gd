extends CharacterBody3D
class_name Player

const GRAVITY = 10
const SPEED = 2
const JUMP_STRENGTH = 5

const POSITION_CHECK_PERIOD = 0.2

var can_move : bool = true
var map : Map

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision: PointCollision = $CollisionShape3D


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
	if Input.is_action_just_pressed("left"):
		velocity -= basis.x * SPEED
	if Input.is_action_just_pressed("right"):
		velocity += basis.x * SPEED
	if Input.is_action_just_pressed("jump"):
		velocity += basis.y * JUMP_STRENGTH

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_check_position()

# Making the player face the right direction - to be optimized
func _update_facing_direction() -> void:
	if _is_moving_left():
		sprite.flip_h = true
	elif _is_moving_right():
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

func _is_moving_right() -> bool:
	return (Vector3.RIGHT * basis * velocity).x > 0

func _is_moving_left() -> bool:
	return (Vector3.RIGHT * basis * velocity).x < 0

func _update_visibility() -> void:
	if !map.cell_in_view(map.local_to_map(position)):
		sprite.modulate = Color("444444")
	else:
		sprite.modulate = Color.WHITE


func _check_vertical_position() -> void:
	if _is_falling():
		var character_bottom : Vector3 = collision.get_point_position(
				PointCollision.Position.LOWEST) * basis + position
		var future_cell_position : Vector3i = map.local_to_map(character_bottom + 
				map.cell_size * Vector3.DOWN * basis)
		var future_mesh_id : int = map.get_cell_item(future_cell_position)
		
		var cell_position : Vector3i = map.local_to_map(character_bottom)
		
		if future_mesh_id == map.INVALID_CELL_ITEM:
			var correct_tile_coordinates = map.find_ground(cell_position)
			if correct_tile_coordinates != null:
				move_to_cell(correct_tile_coordinates)
	#elif _is_raising():
		#var character_top : Vector3 = collision.get_point_position(
				#PointCollision.Position.HIGHEST) * basis + position
		#return
		# This actually never should need to be checked
		# as the character is always at the closest to camera cell
		# that it can be on.
		# So moving it to a place closer to camera
		# where it doesn't bonk it's head
		# would be redundant.
		# The character should just bonk its head.
		
		# Hm
		# This might be not true
		# If the character falls on a tile it might not be the closest
	else:
		return

func _check_horizontal_position() -> void:
	var character_side : Vector3
	var future_cell_position : Vector3i
	
	var moving_left : bool
	
	if _is_moving_left():
		character_side = collision.get_point_position(
				PointCollision.Position.LEFT_SIDE_MOST) * basis + position
		future_cell_position = map.local_to_map(character_side + 
				map.cell_size * Vector3.LEFT * basis)
		moving_left = true
	elif _is_moving_right():
		character_side = collision.get_point_position(
				PointCollision.Position.RIGHT_SIDE_MOST) * basis + position
		future_cell_position = map.local_to_map(character_side + 
				map.cell_size * Vector3.RIGHT * basis)
		moving_left = false
	else:
		return
	
	if map.get_cell_item(future_cell_position) != map.INVALID_CELL_ITEM:
		var conditions : Dictionary
		
		if moving_left:
			conditions = {"SELF" : [""], "LEFT" : [""], "LEFTDOWN" : ["Wall"]}
		else:
			conditions = {"SELF" : [""], "RIGHT" : [""], "RIGHTDOWN" : ["Wall"]}
		
		var cell_position : Vector3i = map.local_to_map(character_side)
		var found_cell : Variant = map.find_cell(cell_position, conditions)
		
		if found_cell != null:
			move_to_cell(found_cell)

func _check_position() -> void:
	get_tree().create_timer(POSITION_CHECK_PERIOD).timeout.connect(_check_position)
	
	_check_vertical_position()
	_check_horizontal_position()

func align_in_cell(axis : Vector3) -> void:
	var cell_position = map.local_to_map(position)
	var in_cell_offset : Vector3 = position - map.map_to_local(cell_position)
	var fixed_cell_offset : Vector3 = in_cell_offset * (Vector3.ONE - abs(axis))
	position = map.map_to_local(cell_position) + fixed_cell_offset

func move_to_cell(destination : Vector3i) -> void:
	var cell_position = map.local_to_map(position)
	var in_cell_offset : Vector3 = position - map.map_to_local(cell_position)
	position = map.map_to_local(destination) + in_cell_offset

func handle_camera_rotation_started() -> void:
	velocity = Vector3.ZERO
	can_move = false
	
	sprite.play("idle")
	sprite.pause()

func handle_camera_rotation_finished(new_basis : Basis) -> void:
	basis = new_basis
	can_move = true
	
	sprite.play()
	
	align_in_cell(Vector3.FORWARD * basis)
