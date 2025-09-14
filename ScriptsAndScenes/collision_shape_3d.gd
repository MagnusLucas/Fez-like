extends CollisionShape3D
class_name PointCollision

enum Position{
	LOWEST,
	HIGHEST,
	LEFT_SIDE_MOST,
	RIGHT_SIDE_MOST,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
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
		Position.TOP_LEFT:
			return position + cylinder.height/2 * Vector3.UP + cylinder.radius * Vector3.LEFT
		Position.TOP_RIGHT:
			return position + cylinder.height/2 * Vector3.UP + cylinder.radius * Vector3.RIGHT
		Position.BOTTOM_LEFT:
			return position + cylinder.height/2 * Vector3.DOWN + cylinder.radius * Vector3.LEFT
		Position.BOTTOM_RIGHT:
			return position + cylinder.height/2 * Vector3.DOWN + cylinder.radius * Vector3.RIGHT
		_:
			return position
