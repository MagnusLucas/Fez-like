extends CharacterBody3D
class_name Player

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("go_left"):
		velocity.x -= 2
	if Input.is_action_just_pressed("go_right"):
		velocity.x += 2
	move_and_slide()
