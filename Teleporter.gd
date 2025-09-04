extends RefCounted
class_name Teleporter

var map : Map
var player : Player

func _init(current_map : Map, parent_player : Player) -> void:
	map = current_map
	player = parent_player

func check_position() -> void:
	#print(_get_current_cells())
	_check_horizontal_position()
	_check_vertical_position()

func align_in_cell(axis : Vector3) -> void:
	var cell_position = map.local_to_map(player.position)
	var in_cell_offset : Vector3 = player.position - map.map_to_local(cell_position)
	var fixed_cell_offset : Vector3 = in_cell_offset * (Vector3.ONE - abs(axis))
	player.position = map.map_to_local(cell_position) + fixed_cell_offset

func move_to_cell(destination : Vector3i) -> void:
	print("TP!")
	var cell_position = map.local_to_map(player.position)
	var in_cell_offset : Vector3 = player.position - map.map_to_local(cell_position)
	player.position = map.map_to_local(destination) + in_cell_offset

func _get_current_cells() -> Array[Vector3i]:
	var collision : PointCollision = player.collision
	var corners := [collision.get_point_position(PointCollision.Position.TOP_LEFT),
			collision.get_point_position(PointCollision.Position.TOP_RIGHT),
			collision.get_point_position(PointCollision.Position.BOTTOM_LEFT),
			collision.get_point_position(PointCollision.Position.BOTTOM_RIGHT),
	]
	var cells : Array[Vector3i]
	var dict := {}
	for corner in corners:
		dict[map.local_to_map(player.position + corner * player.basis.inverse())] = true
	cells.assign(dict.keys())
	return cells

func _check_vertical_position() -> void:
	if player.is_falling():
		var character_bottom : Vector3 = player.collision.get_point_position(
				PointCollision.Position.LOWEST) * player.basis + player.position
		var future_cell_position : Vector3i = map.local_to_map(character_bottom + 
				map.cell_size * Vector3.DOWN * player.basis)
		var future_mesh_id : int = map.get_cell_item(future_cell_position)
		
		var cell_position : Vector3i = map.local_to_map(character_bottom)
		
		if future_mesh_id == map.INVALID_CELL_ITEM:
			var correct_tile_coordinates = map.find_ground(cell_position)
			if correct_tile_coordinates != null:
				move_to_cell(correct_tile_coordinates)
	#elif is_raising():
		#var character_top : Vector3 = collision.get_point_position(
				#PointCollision.Position.HIGHEST) * basis + position
		#return
		# This actually never should need to be checked
		# as the character is always at the closest to camera cell
		# that it can be on.
		# So moving it to a place closer to camera
		# where it doesn't bonk it's head
		# would be redundant.
		# The character should just bonk its head.
		
		# Hm
		# This might be not true
		# If the character falls on a tile it might not be the closest
	else:
		return

func _check_horizontal_position() -> void:
	var character_side : Vector3
	var future_cell_position : Vector3i
	
	var moving_left : bool
	
	if player.is_moving_left():
		character_side = player.collision.get_point_position(
				PointCollision.Position.LEFT_SIDE_MOST) * player.basis.inverse() + player.position
		future_cell_position = map.local_to_map(character_side + 
				map.cell_size * Vector3.LEFT * player.basis.inverse())
		moving_left = true
	elif player.is_moving_right():
		character_side = player.collision.get_point_position(
				PointCollision.Position.RIGHT_SIDE_MOST) * player.basis.inverse() + player.position
		future_cell_position = map.local_to_map(character_side + 
				map.cell_size * Vector3.RIGHT * player.basis.inverse())
		moving_left = false
	else:
		return
	
	if map.empty_at_position(future_cell_position):
		pass
	else:
		var conditions : Dictionary
		
		# Looking for ground
		if moving_left:
			conditions = {"SELF" : [""], "LEFT" : [""], "LEFTDOWN" : Globals.GROUND_CELLS}
		else:
			conditions = {"SELF" : [""], "RIGHT" : [""], "RIGHTDOWN" : Globals.GROUND_CELLS}
		
		var cell_position : Vector3i = map.local_to_map(character_side)
		var found_cell : Variant = map.find_cell(cell_position, conditions)
		var cell_difference : Vector3i = future_cell_position - cell_position
		if found_cell != null and map.is_cell_visible(Vector3i(found_cell) + cell_difference):
			move_to_cell(found_cell)

func _handle_visible_player() -> void:
	pass

func _handle_invisible_player() -> void:
	pass
