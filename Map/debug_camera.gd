extends Node3D

const ROTATION_SPEED = 0.01

func _input(event: InputEvent) -> void:
	if Input.get_mouse_button_mask() & 1 << 2 and event is InputEventMouseMotion:
		var moved_by : Vector2 = event.relative
		rotate(basis.y, - moved_by.x * ROTATION_SPEED)
