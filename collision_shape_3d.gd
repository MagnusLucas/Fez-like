extends CollisionShape3D
class_name PointCollision

enum Position{
	LOWEST,
	HIGHEST,
	LEFT_SIDE_MOST,
	RIGHT_SIDE_MOST,
}

func get_point_position(type : Position) -> Vector3:
	var cylinder : CylinderShape3D = shape
	match type:
		Position.LOWEST:
			return position + cylinder.height/2 * Vector3.DOWN
		Position.HIGHEST:
			return position + cylinder.height/2 * Vector3.UP
		Position.LEFT_SIDE_MOST:
			return position + cylinder.radius * Vector3.LEFT
		Position.RIGHT_SIDE_MOST:
			return position + cylinder.radius * Vector3.RIGHT
		_:
			return position
