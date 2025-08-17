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
		
		camera_origin.connect("camera_rotation_started", player.stop_movement)
		camera_origin.connect("camera_rotation_finished", player.update_rotation)

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

# One could check all cells on map for whether they are on the axis
# Or all coordinates on axis for whether they have a cell

# The second one should be quicker
func get_visible_cells_in_axis(cell_in_axis : Vector3i, axis : Vector3) -> AABB:
	var used_AABB : AABB = get_used_AABB()
	var axis_coordinates = (Vector3.ONE - abs(axis)) * Vector3(cell_in_axis)
	
	# Making sure the iteration always goes along FORWARD of camera, so that first seen cell is the end of view
	var first_axis_cell : Vector3i = (used_AABB.end if axis == abs(axis) 
		else used_AABB.position) * axis + axis_coordinates
	var last_axis_cell : Vector3i = (used_AABB.position if axis == abs(axis) 
		else used_AABB.end) * axis + axis_coordinates
	
	for coordinate in abs(axis.dot(used_AABB.size)) + 1:
		var cell_position : Vector3i = Vector3(first_axis_cell) - abs(axis) * coordinate
		
		# first_cell > cell_position > last_cell
		if get_cell_item(cell_position) != INVALID_CELL_ITEM:
			if axis == abs(axis):
				return AABB(last_axis_cell, cell_position - last_axis_cell)
			else:
				return AABB(cell_position, first_axis_cell - cell_position)
	return AABB(last_axis_cell, first_axis_cell - last_axis_cell)

# [found_correct_ground : bool, ground_coordinates]
func find_ground(player_position : Vector3i, player_down : Vector3i = Vector3i.DOWN) -> Array:
	var used_AABB : AABB = get_used_AABB()
	var axis : Vector3 = camera_origin.get_camera_normal()
	var axis_coordinates = (Vector3.ONE - abs(axis)) * Vector3(player_position)
	
	# Making sure the iteration always goes along FORWARD of camera, so that first seen cell is the end of view
	var first_axis_cell : Vector3i = (used_AABB.end if axis == abs(axis) 
		else used_AABB.position) * axis + axis_coordinates
	var _last_axis_cell : Vector3i = (used_AABB.position if axis == abs(axis) 
		else used_AABB.end) * axis + axis_coordinates
	
	for coordinate in abs(axis.dot(used_AABB.size)) + 1:
		var cell_position : Vector3i = Vector3(first_axis_cell) - abs(axis) * coordinate
		
		# first_cell > cell_position > last_cell
		if (get_cell_item(cell_position) != INVALID_CELL_ITEM and 
			get_cell_item(cell_position + player_down) == INVALID_CELL_ITEM):
			return [true, cell_position]
	return [false, Vector3i.ZERO]

func cell_in_view(cell_position : Vector3i) -> bool:
	var camera_normal : Vector3i = camera_origin.get_camera_normal()
	return get_visible_cells_in_axis(cell_position, camera_normal).has_point(cell_position)
