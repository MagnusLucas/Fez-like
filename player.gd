extends CharacterBody3D
class_name Player

const GRAVITY = 10
const SPEED = 2
const JUMP_STRENGTH = 20



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


func stop_movement():
	velocity = Vector3.ZERO

func update_rotation(new_basis : Basis):
	basis = new_basis
