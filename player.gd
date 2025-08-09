extends CharacterBody3D
class_name Player

const GRAVITY = 10
const SPEED = 2
const JUMP_STRENGTH = 5

const POSITION_CHECK_PERIOD = 0.2

func _ready() -> void:
	_check_position()

func _process(delta: float) -> void:
	if !is_on_floor():
		velocity -= basis.y * GRAVITY * delta
	if Input.is_action_just_pressed("go_left"):
		velocity -= basis.x * SPEED
	if Input.is_action_just_pressed("go_right"):
		velocity += basis.x * SPEED
	if Input.is_action_just_pressed("jump"):
		velocity += basis.y * JUMP_STRENGTH
	move_and_slide()

func _check_position():
	var map : Map = get_parent()
	get_tree().create_timer(POSITION_CHECK_PERIOD).timeout.connect(_check_position)
	
	var future_cell_position : Vector3i = map.local_to_map(position + map.cell_size * velocity.normalized())
	var current_cell_position : Vector3i = map.local_to_map(position)
	print(current_cell_position, " ", future_cell_position)
	
	var mesh_id : int = map.get_cell_item(future_cell_position)
	if mesh_id == map.INVALID_CELL_ITEM:
		print("Empty")
	else:
		print(map.mesh_library.get_item_name(mesh_id))
	

func stop_movement():
	velocity = Vector3.ZERO

func update_rotation(new_basis : Basis):
	basis = new_basis
