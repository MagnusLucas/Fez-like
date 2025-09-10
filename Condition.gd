extends RefCounted
class_name Condition

var verbal_direction : String
var direction : Vector3i
var cell_types : Dictionary
var is_visible : bool
var is_visibility_important : bool

func _init(local_direction : Variant, correct_cell_types : Dictionary,
		should_be_visible : Variant = null) -> void:
	cell_types = correct_cell_types
	if local_direction is String:
		verbal_direction = local_direction
		direction = str_to_vec(verbal_direction)
	else:
		direction = local_direction
		verbal_direction = vec_to_string(direction)
	if should_be_visible != null:
		is_visible = bool(should_be_visible)
		is_visibility_important = true
	else:
		is_visibility_important = false

func evaluate(map : Map, cell_position : Vector3i, camera_basis : Basis) -> bool:
	var checked_cell = cell_position + Vector3i(
			(Vector3(direction) * camera_basis.inverse()).round()
	)
	if is_visibility_important:
		if map.is_cell_visible(checked_cell) != is_visible:
			return false
	var cell_id = map.get_cell_item(checked_cell)
	
	if cell_id == -1:
		return cell_types.has("EMPTY")
	
	var cell_name = map.mesh_library.get_item_name(cell_id)
	if !cell_types.has(cell_name):
		return false
	return true

func _to_string() -> String:
	var result := verbal_direction + " is one of " + str(cell_types.keys())
	if is_visibility_important:
		result += " and "
		if !is_visible:
			result += "not "
		result += "visible"
	return result

static func ground_conditions() -> Array[Condition]:
	return [Condition.new("SELF", Globals.EMPTY_CELL),
			Condition.new("DOWN", Globals.GROUND_CELLS)]

static func str_to_vec(string : String) -> Vector3i:
	var result = Vector3i.ZERO
	if string.contains("LEFT"):
		result += Vector3i.LEFT
	elif string.contains("RIGHT"):
		result += Vector3i.RIGHT
	if string.contains("DOWN"):
		result += Vector3i.DOWN
	elif string.contains("UP"):
		result += Vector3i.UP
	if string.contains("BACK"):
		result += Vector3i.BACK
	elif string.contains("FORWARD"):
		result += Vector3i.FORWARD
	return result

static func vec_to_string(vector : Vector3i) -> String:
	var vector_names := {
		"LEFT" : Vector3i.LEFT,
		"RIGHT" : Vector3i.RIGHT,
		"DOWN" : Vector3i.DOWN,
		"UP" : Vector3i.UP,
		"BACK" : Vector3i.BACK,
		"FORWARD" : Vector3i.FORWARD,
	}
	var result := ""
	for name in vector_names:
		var multiplied = vector * vector_names[name]
		if max(multiplied.x, multiplied.y, multiplied.z) > 0:
			result += name
	return result
