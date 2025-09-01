extends GridMap
class_name Map

const PLAYER_SCENE = preload("res://player.tscn")
const DOOR_SCENE = preload("res://Map/door.tscn")
const BASE_CELL_COLLIDER_SCENE = preload("res://Map/base_cell_collider.tscn")

const SCRIPTED_SCENES : Dictionary[String, Resource] = {
	"Player" : PLAYER_SCENE,
	"Door" : DOOR_SCENE,
	"InvisibleWall" : BASE_CELL_COLLIDER_SCENE,
}

@export var camera_follows_player : bool = true
@onready var camera_origin: CameraOrigin = $CameraOrigin


func _ready() -> void:
	_instantiate_scripted_scenes()
	get_visible_cells_in_axis(Vector3.ZERO, Vector3.FORWARD)
	if camera_follows_player:
		var player : Player = find_child("Player", false, false)
		camera_origin.player = player
		
		camera_origin.connect("camera_rotation_started", player.handle_camera_rotation_started)
		camera_origin.connect("camera_rotation_finished", player.handle_camera_rotation_finished)

func _instantiate_scripted_scenes() -> void:
	var used_cells = get_used_cells()
	for cell_position in used_cells:
		var item = get_cell_item(cell_position)
		var item_name = mesh_library.get_item_name(item)
		if item_name in SCRIPTED_SCENES:
			var instance = SCRIPTED_SCENES[item_name].instantiate()
			add_child(instance, true)
			instance.position = map_to_local(cell_position)
			set_cell_item(cell_position, INVALID_CELL_ITEM)

func get_used_AABB() -> AABB:
	var used_cells : Array[Vector3i] = get_used_cells()
	var min_x = +INF
	var min_y = +INF
	var min_z = +INF
	var max_x = -INF
	var max_y = -INF
	var max_z = -INF
	for cell in used_cells:
		if cell.x < min_x:
			min_x = cell.x
		if cell.y < min_y:
			min_y = cell.y
		if cell.z < min_z:
			min_z = cell.z
		if cell.x > max_x:
			max_x = cell.x
		if cell.y > max_y:
			max_y = cell.y
		if cell.z > max_z:
			max_z = cell.z
	return AABB(Vector3i(min_x, min_y, min_z), Vector3i(max_x - min_x, max_y - min_y, max_z - min_z))

func str_to_vec(string : String, global : bool = false) -> Vector3i:
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
	if global:
		return result
	else:
		var camera_basis : Basis = camera_origin.basis
		result = Vector3(result) * camera_basis.inverse()
		return result

func cell_conditions_fulfilled(cell_position : Vector3i, 
		searched_type_names : Array, exclusive : bool = false) -> bool:
	
	var cell_id : int = get_cell_item(cell_position)
	if cell_id == INVALID_CELL_ITEM:
		if searched_type_names.has("") and not exclusive:
			return true
		else:
			return false
	
	var cell_name = mesh_library.get_item_name(cell_id)
	return searched_type_names.has(cell_name) and not exclusive

func neighbourhood_conditions_fulfilled(cell_position : Vector3i, 
		conditions : Dictionary) -> bool:
	for condition in conditions:
		if !cell_conditions_fulfilled(cell_position + str_to_vec(condition),
				conditions[condition]):
			return false
	return true

func find_cell_in_axis(first_cell : Vector3, last_cell : Vector3, 
		conditions : Dictionary) -> Variant:
	
	var iteration_size := int((last_cell - first_cell).length())
	var axis : Vector3 = (last_cell - first_cell)/iteration_size
	
	for coordinate in range(iteration_size + 1):
		var cell_position : Vector3 = first_cell + axis * coordinate
		
		if neighbourhood_conditions_fulfilled(cell_position, conditions):
			return cell_position
	return null

func find_cell(cell_in_axis : Vector3i, conditions : Dictionary) -> Variant:
	var limits = get_iteration_limits(cell_in_axis)
	return find_cell_in_axis(limits["first_cell"], limits["last_cell"], conditions)

func get_iteration_limits(cell_in_axis : Vector3i, axis : Vector3 = camera_origin.get_camera_normal()) -> Dictionary:
	var used_AABB : AABB = get_used_AABB()
	var axis_coordinates = (Vector3.ONE - abs(axis)) * Vector3(cell_in_axis)
	var positive_axis : bool = axis == abs(axis) 
	
	# Making sure the iteration always goes along FORWARD of camera, so that first seen cell is the end of view
	var first_axis_cell : Vector3 = used_AABB.position * abs(axis) + axis_coordinates
	var last_axis_cell : Vector3 = used_AABB.end * abs(axis) + axis_coordinates
	if !positive_axis:
		var tmp : Vector3 = first_axis_cell
		first_axis_cell = last_axis_cell
		last_axis_cell = tmp
	
	return {"first_cell" : first_axis_cell, "last_cell" : last_axis_cell}

# One could check all cells on map for whether they are on the axis
# Or all coordinates on axis for whether they have a cell
# The second one should be quicker
func get_visible_cells_in_axis(cell_in_axis : Vector3i, axis : Vector3) -> AABB:
	var positive_axis : bool = axis == abs(axis)
	
	var limits = get_iteration_limits(cell_in_axis, axis)
	var first_cell = limits["first_cell"]
	var last_cell = limits["last_cell"]
	
	var conditions : Dictionary = {"SELF" : Globals.VIEW_OBSTRUCTING_CELLS}
	
	var cell_position : Variant = find_cell_in_axis(first_cell, last_cell, conditions)
	
	if cell_position == null:
		cell_position = last_cell
	if positive_axis:
		return AABB(first_cell, cell_position - first_cell)
	else:
		return AABB(cell_position, first_cell - cell_position)

# The variant is either null or the found position
func find_ground(player_position : Vector3i) -> Variant:
	var axis : Vector3 = camera_origin.get_camera_normal()
	var limits = get_iteration_limits(player_position, axis)
	
	var first_axis_cell : Vector3i = limits["first_cell"]
	var last_axis_cell : Vector3i = limits["last_cell"]
	
	var conditions : Dictionary = {"SELF" : [""], "DOWN" : ["Wall"]}
	
	return find_cell_in_axis(first_axis_cell, last_axis_cell, conditions)

func cell_in_view(cell_position : Vector3i) -> bool:
	var camera_normal : Vector3i = camera_origin.get_camera_normal()
	return get_visible_cells_in_axis(cell_position, camera_normal).has_point(cell_position)
