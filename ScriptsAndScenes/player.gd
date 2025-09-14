extends CharacterBody3D
class_name Player

const GRAVITY = 10
const SPEED = 4
const JUMP_STRENGTH = 5
const DIE_DELAY := 1.0


var can_move : bool = true
var map : Map
var teleporter : Teleporter

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision: PointCollision = $CollisionShape3D
@onready var die_delay_timer: Timer = $DieDelay


func _ready() -> void:
	if get_parent() is Map:
		map = get_parent()
		teleporter = Teleporter.new(map, self)

func _process(delta: float) -> void:
	var previous_velocity : Vector3 = velocity
	_move(delta)
	_update_animation(previous_velocity)

func _move(delta: float) -> void:
	if can_move:
		_handle_input()
		if !is_on_floor():
			velocity -= basis.y * GRAVITY * delta
		teleporter.check_position(delta)
	_update_facing_direction()
	_handle_timer(delta)
	move_and_slide()
	_update_visibility()

func _handle_input() -> void:
	var local_velocity : Vector3 = velocity * basis
	local_velocity.x = 0
	if Input.is_action_pressed("left"):
		local_velocity.x -= SPEED
	if Input.is_action_pressed("right"):
		local_velocity.x += SPEED
	velocity = local_velocity * basis.inverse()
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity += basis.y * JUMP_STRENGTH

func _handle_timer(delta: float) -> void:
	var was_in_borders : bool = _is_in_borders(position)
	var is_in_borders : bool = _is_in_borders(position + velocity * delta)
	if was_in_borders and !is_in_borders:
		die_delay_timer.start(DIE_DELAY)
	elif is_in_borders and !was_in_borders:
		die_delay_timer.stop()

func _is_in_borders(player_position : Vector3) -> bool:
	var map_position : Vector3i = map.local_to_map(player_position)
	return map.used_aabb.has_point(map_position)

# Making the player face the right direction - to be optimized
func _update_facing_direction() -> void:
	if is_moving_left():
		sprite.flip_h = true
	elif is_moving_right():
		sprite.flip_h = false

func _update_animation(previous_velocity : Vector3) -> void:
	if previous_velocity == Vector3.ZERO and velocity != Vector3.ZERO:
		sprite.play("walk")
	elif previous_velocity != Vector3.ZERO and velocity == Vector3.ZERO:
		sprite.play("idle")

func is_falling() -> bool:
	if is_on_floor():
		return false
	return (Vector3.UP * basis * velocity).y < 0

func is_raising() -> bool:
	if is_on_floor():
		return false
	return (Vector3.UP * basis * velocity).y > 0

func is_moving_right() -> bool:
	return (Vector3.RIGHT * basis * velocity).x > 0

func is_moving_left() -> bool:
	return (Vector3.RIGHT * basis * velocity).x < 0

func _update_visibility() -> void:
	if !map.is_cell_visible(map.local_to_map(position)):
		sprite.modulate = Color("444444")
	else:
		sprite.modulate = Color.WHITE


func handle_camera_rotation_started(new_basis : Basis) -> void:
	basis = new_basis
	
	velocity = Vector3.ZERO
	can_move = false
	
	sprite.play("idle")
	sprite.pause()

func handle_camera_rotation_finished() -> void:
	can_move = true
	
	sprite.play()
	
	teleporter.align_in_cell(Vector3.FORWARD * basis)


func _on_die_delay_timeout() -> void:
	teleporter.move_to_cell(map.player_spawn_point)
