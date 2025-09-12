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

var visible_cells : Dictionary
var used_aabb : AABB

func _ready() -> void:
	_instantiate_scripted_scenes()
	used_aabb = get_used_AABB()
	used_aabb.position -= Vector3.ONE # Fix so that the player can always tp visible/invisible
	used_aabb.size += Vector3.ONE * 2 # Remove to allow it
	calculate_axis_visibility(Basis.IDENTITY)
	if camera_follows_player:
		var player : Player = find_child("Player", false, false)
		camera_origin.player = player
		
		camera_origin.connect("camera_rotation_started", player.handle_camera_rotation_started)
		camera_origin.connect("camera_rotation_started", calculate_axis_visibility)
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


func calculate_axis_visibility(new_basis : Basis) -> void:
	var new_camera_normal : Vector3 = (Vector3.FORWARD * new_basis.inverse()).round()
	var checked_axes : Vector3 = Vector3.ONE - abs(new_camera_normal)
	
	var iteration_plane : AABB = AABB(used_aabb.position, used_aabb.size * checked_axes)
	
	visible_cells = {}
	
	for x in iteration_plane.size.x + 1:
		for y in iteration_plane.size.y + 1:
			for z in iteration_plane.size.z + 1:
				var cell_coordinates : Vector3i = (used_aabb.position * checked_axes + Vector3(x,y,z)).round()
				
				visible_cells[cell_coordinates] = get_visible_cells_in_axis(cell_coordinates, new_camera_normal)
	return


func get_axis_coords(point_on_axis : Vector3i, axis : Vector3i = camera_origin.get_camera_normal()) -> Vector3i:
	return point_on_axis * (Vector3i.ONE - abs(axis))

func is_cell_on_ground(cell_position : Vector3i) -> bool:
	return neighbourhood_conditions_fulfilled(cell_position, Condition.GROUND_CONDITIONS())

func neighbourhood_conditions_fulfilled(cell_position : Vector3i, 
		conditions : Array[Condition]) -> bool:
	for condition in conditions:
		if !condition.evaluate(self, cell_position, camera_origin.basis):
			return false
	return true

func find_cell_in_axis(first_cell : Vector3, last_cell : Vector3,  
		conditions : Array[Condition]) -> Variant:
	
	var iteration_size := int((last_cell - first_cell).length())
	var axis : Vector3 = (last_cell - first_cell)/iteration_size
	
	for coordinate in range(iteration_size + 1):
		var cell_position : Vector3 = first_cell + axis * coordinate
		
		if neighbourhood_conditions_fulfilled(cell_position, conditions):
			return cell_position
	return null

func find_cell(cell_in_axis : Vector3i, conditions : Array[Condition]) -> Variant:
	var limits = get_iteration_limits(cell_in_axis)
	return find_cell_in_axis(limits["first_cell"], limits["last_cell"], conditions)

func get_iteration_limits(cell_in_axis : Vector3i, axis : Vector3 = camera_origin.get_camera_normal()) -> Dictionary:
	var axis_coordinates = (Vector3.ONE - abs(axis)) * Vector3(cell_in_axis)
	var positive_axis : bool = axis == abs(axis) 
	
	# Making sure the iteration always goes along FORWARD of camera
	var first_axis_cell : Vector3 = used_aabb.position * abs(axis) + axis_coordinates
	var last_axis_cell : Vector3 = used_aabb.end * abs(axis) + axis_coordinates
	if !positive_axis:
		var tmp : Vector3 = first_axis_cell
		first_axis_cell = last_axis_cell
		last_axis_cell = tmp
	
	return {"first_cell" : first_axis_cell.round(), "last_cell" : last_axis_cell.round()}

# One could check all cells on map for whether they are on the axis
# Or all coordinates on axis for whether they have a cell
# The second one should be quicker
func get_visible_cells_in_axis(cell_in_axis : Vector3i, axis : Vector3) -> AABB:
	var positive_axis : bool = axis == abs(axis)
	
	var limits = get_iteration_limits(cell_in_axis, axis)
	var first_cell = limits["first_cell"]
	var last_cell = limits["last_cell"]
	
	var conditions : Array[Condition] = [Condition.new("SELF", Globals.VIEW_OBSTRUCTING_CELLS)]
	
	var cell_position : Variant = find_cell_in_axis(first_cell, last_cell, conditions)
	if cell_position == null:
		cell_position = last_cell
	if positive_axis:
		return AABB(first_cell, cell_position - first_cell)
	else:
		return AABB(cell_position, first_cell - cell_position)

# The variant is either null or the found position
func find_ground(player_position : Vector3i, cell_visible : bool = true) -> Variant:
	var axis : Vector3 = camera_origin.get_camera_normal()
	var limits = get_iteration_limits(player_position, (1 if cell_visible else -1) * axis)
	
	var first_axis_cell : Vector3i = limits["first_cell"]
	var last_axis_cell : Vector3i = limits["last_cell"]
	
	return find_cell_in_axis(first_axis_cell, last_axis_cell, Condition.GROUND_CONDITIONS())

func is_cell_visible(cell_position : Vector3i) -> bool:
	var axis_coords : Vector3i = get_axis_coords(cell_position)
	if !visible_cells.has(axis_coords):
		return true
	var visible_aabb : AABB = visible_cells[axis_coords]
	return visible_aabb.has_point(cell_position)

func is_cell_empty(cell_position : Vector3i) -> bool:
	return neighbourhood_conditions_fulfilled(cell_position, Condition.EMPTY())
