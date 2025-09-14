extends Node3D
class_name CameraOrigin

var can_rotate : bool = true

# Used only if the camera should follow the player
var player : Player = null

signal camera_rotation_finished()
signal camera_rotation_started(basis : Basis)

const CAMERA_ORIGIN = preload("res://ScriptsAndScenes/camera_origin.tscn")

static func instantiate() -> CameraOrigin:
	return CAMERA_ORIGIN.instantiate()

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
	var future_basis = basis.rotated(Vector3.UP, -angle_radians)
	camera_rotation_started.emit(future_basis)
	tween.tween_property(self, "rotation:y", rotation.y - angle_radians, TWEEN_TIME)
	
	tween.finished.connect(func() -> void: 
		can_rotate = true
		basis.x.round()
		basis.y.round()
		basis.z.round()
		camera_rotation_finished.emit()
	)

func get_camera_normal() -> Vector3:
	return (Vector3.FORWARD * basis.inverse())
