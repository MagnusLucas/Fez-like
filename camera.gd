extends Node3D
class_name CameraOrigin

var can_rotate : bool = true

# Used only if the camera should follow the player
var player : Player = null

signal camera_rotation_finished(basis : Basis)
signal camera_rotation_started()

func _process(_delta: float) -> void:
	if player:
		position = player.position
	if Input.is_action_just_pressed("rotate_left") and can_rotate:
		tween_y_rotation(PI/2)
	if Input.is_action_just_pressed("rotate_right") and can_rotate:
		tween_y_rotation(-PI/2)
	
	
	if Input.is_action_just_pressed("rotate_up") and can_rotate:
		print_debug("TODO: rotating the camera up")
	if Input.is_action_just_pressed("rotate_down") and can_rotate:
		print_debug("TODO: rotating the camera down")


func tween_y_rotation(angle_radians : float) -> void:
	const TWEEN_TIME = 1
	var tween : Tween = get_tree().create_tween()
	can_rotate = false
	camera_rotation_started.emit()
	tween.tween_property(self, "rotation:y", rotation.y - angle_radians, TWEEN_TIME)
	tween.finished.connect(func() -> void: 
		can_rotate = true
		camera_rotation_finished.emit(basis)
	)

func get_camera_normal() -> Vector3:
	return (Vector3.FORWARD * basis.inverse())
