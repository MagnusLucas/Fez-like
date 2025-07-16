extends CharacterBody3D
class_name Player

const GRAVITY = 10
const SPEED = 2
const JUMP_STRENGTH = 20



func _process(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	if Input.is_action_just_pressed("go_left"):
		velocity.x -= SPEED
	if Input.is_action_just_pressed("go_right"):
		velocity.x += SPEED
	if Input.is_action_just_pressed("jump"):
		velocity.y += JUMP_STRENGTH
	move_and_slide()
