extends RefCounted
class_name Teleporter

var map : Map
var player : Player

func _init(current_map : Map, parent_player : Player) -> void:
	map = current_map
	player = parent_player

func check_position(delta : float) -> void:
	var velocity : Vector3 = player.velocity
	var current_cells := _get_inhabitet_cells_at_position(player.position)
	var future_cells := _get_inhabitet_cells_at_position(player.position + velocity * delta)
	var new_cells : Array[Vector3i] = Globals.subtract_arrays(future_cells, current_cells)
	
	if new_cells.is_empty():
		return
	
	var visibility_change : float = _visibility_change(current_cells, future_cells)
	var player_position : Vector3i = map.local_to_map(player.position)
	
	if visibility_change < 0: # Getting less visible
		_handle_hiding(current_cells, new_cells, player_position)
	elif visibility_change == 0:
		_handle_no_visibility_change(current_cells, new_cells, player_position)
	else:
		_handle_showing()


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


func _get_directional(position : Vector3i, cells : Array[Vector3i]) -> Array[Vector3i]:
	var result : Array[Vector3i]
	for cell in cells:
		result.append(cell - position)
	return result


func _get_inhabitet_cells_at_position(position : Vector3, 
		corners : Array[PointCollision.Position] = [
				PointCollision.Position.TOP_LEFT,
				PointCollision.Position.TOP_RIGHT,
				PointCollision.Position.BOTTOM_LEFT,
				PointCollision.Position.BOTTOM_RIGHT,
		]) -> Array[Vector3i]:
	var collision : PointCollision = player.collision
	var corner_positions : Array[Vector3]
	for corner in corners:
		corner_positions.append(collision.get_point_position(corner))
	var cells : Array[Vector3i]
	var dict := {}
	for corner in corner_positions:
		dict[map.local_to_map(position + corner * player.basis.inverse())] = true
	cells.assign(dict.keys())
	return cells

# True - visible, false - invisible, null - somewhat visible
func _is_player_visibile(inhabited_cells : Array[Vector3i]) -> Variant:
	var visibility : bool = map.is_cell_visible(inhabited_cells[0])
	for cell in inhabited_cells:
		if visibility != map.is_cell_visible(cell):
			return null
	return visibility

func _handle_hiding(current_cells : Array[Vector3i],
		new_cells : Array[Vector3i], player_position : Vector3i) -> void:
	match new_cells.size():
		1:
			var direction : Vector3i = new_cells[0] - player_position
			print("Simple hiding ", Condition.vec_to_string(direction))
			match direction:
				Vector3i.UP:
					if !map.is_cell_empty(player_position + direction):
						var conditions : Array[Condition] = [
							Condition.new("SELF", Globals.EMPTY_CELL, map.is_cell_visible(player_position)),
							Condition.new("UP", Globals.EMPTY_CELL)]
						var correct_cell = map.find_cell(player_position, conditions)
						move_to_cell(correct_cell)
				Vector3i.DOWN:
					if map.is_cell_empty(player_position + direction):
						var conditions : Array[Condition] = [
							Condition.new("SELF", Globals.EMPTY_CELL, true),
							Condition.new("DOWN", Globals.GROUND_CELLS)]
						var correct_cell = map.find_cell(player_position, conditions)
						if correct_cell != null:
							move_to_cell(correct_cell)
						else:
							conditions = [
							Condition.new("SELF", Globals.EMPTY_CELL, true),
							Condition.new("DOWN", Globals.EMPTY_CELL, true)]
							correct_cell = map.find_cell(player_position, conditions)
							if correct_cell != null:
								move_to_cell(correct_cell)
				Vector3i.LEFT, Vector3i.RIGHT:
					if !map.is_cell_empty(player_position + direction):
						var conditions : Array[Condition] = [
							Condition.new("SELF", Globals.EMPTY_CELL, true),
							Condition.new(direction, Globals.EMPTY_CELL, true)]
						var correct_cell = map.find_cell(player_position, conditions)
						if correct_cell != null:
							move_to_cell(correct_cell)
						else:
							conditions = [
								Condition.new("SELF", Globals.EMPTY_CELL, true),
								Condition.new(direction, Globals.VIEW_OBSTRUCTING_CELLS)]
							correct_cell = map.find_cell(player_position, conditions)
							move_to_cell(correct_cell)
		2:
			var directional_to_new : Array[Vector3i] = Globals.subtract_vector_from_each(new_cells, player_position)
			var direction : Vector3i
			if directional_to_new[0].length_squared() == 1:
				direction = directional_to_new[0]
			else:
				direction = directional_to_new[1]
			print("Two-cell hiding ", Condition.vec_to_string(direction))
			match direction:
				Vector3i.UP:
					var conditions : Array[Condition] = [
						Condition.new(current_cells[0] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[0])),
						Condition.new(current_cells[1] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[1])),
						Condition.new(new_cells[0] - player_position, Globals.EMPTY_CELL),
						Condition.new(new_cells[1] - player_position, Globals.EMPTY_CELL)
						]
					var correct_cell = map.find_cell(player_position, conditions)
					# Check if the player is becoming fully invisible after tp
					if correct_cell != null:
						var future_cells : Array[Vector3i] = Globals.subtract_vector_from_each(directional_to_new, -correct_cell)
						future_cells += Globals.subtract_vector_from_each(current_cells, player_position - correct_cell)
						if _is_player_visibile(future_cells) != false:
							move_to_cell(correct_cell)
				#Vector3i.DOWN:
					#if map.is_cell_empty(new_cells[0]) and map.is_cell_empty(new_cells[1]):
						#var conditions : Array[Condition] = [
							#Condition.new(current_cells[0] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[0])),
							#Condition.new(current_cells[1] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[1])),
							#Condition.new(new_cells[0] - player_position, Globals.GROUND_CELLS)
							#]
						#var correct_cell = map.find_cell(player_position, conditions)
						#if correct_cell != null:
							#move_to_cell(correct_cell)
						#else:
							#conditions = [
							#Condition.new(current_cells[0] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[0])),
							#Condition.new(current_cells[1] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[1])),
							#Condition.new(new_cells[1] - player_position, Globals.GROUND_CELLS)
							#]
							#correct_cell = map.find_cell(player_position, conditions)
							#if correct_cell != null:
								#move_to_cell(correct_cell)
		3:
			print("This never happens.")
			# This happens, like, never.
	return

func _handle_showing() -> void:
	return


func _handle_no_visibility_change(current_cells : Array[Vector3i],
		new_cells : Array[Vector3i], player_position : Vector3i) -> void:
	# Keep on ground
	# Avoid walls
	
	# First figure out the case
	match new_cells.size():
		1:
			var direction : Vector3i = new_cells[0] - player_position
			match direction:
				Vector3i.UP:
					if !map.is_cell_empty(player_position + direction):
						var conditions : Array[Condition] = [
							Condition.new("SELF", Globals.EMPTY_CELL, map.is_cell_visible(player_position)),
							Condition.new("UP", Globals.EMPTY_CELL)]
						var correct_cell = map.find_cell(player_position, conditions)
						move_to_cell(correct_cell)
				Vector3i.DOWN:
					if map.is_cell_empty(player_position + direction):
						var conditions : Array[Condition] = [
							Condition.new("SELF", Globals.EMPTY_CELL, map.is_cell_visible(player_position)),
							Condition.new("DOWN", Globals.GROUND_CELLS)]
						var correct_cell = map.find_cell(player_position, conditions)
						if correct_cell != null:
							move_to_cell(correct_cell)
				Vector3i.LEFT, Vector3i.RIGHT:
					if !map.is_cell_empty(player_position + direction):
						var conditions : Array[Condition] = [
							Condition.new("SELF", Globals.EMPTY_CELL, map.is_cell_visible(player_position)),
							Condition.new(direction, Globals.EMPTY_CELL, true)]
						var correct_cell = map.find_cell(player_position, conditions)
						if correct_cell != null:
							move_to_cell(correct_cell)
		2:
			var directional_to_new : Array[Vector3i] = Globals.subtract_vector_from_each(new_cells, player_position)
			var direction : Vector3i
			if directional_to_new[0].length_squared() == 1:
				direction = directional_to_new[0]
			else:
				direction = directional_to_new[1]
			match direction:
				Vector3i.UP, Vector3i.LEFT, Vector3i.RIGHT:
					if !map.is_cell_empty(new_cells[0]) or !map.is_cell_empty(new_cells[1]):
						var conditions : Array[Condition] = [
							Condition.new(current_cells[0] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[0])),
							Condition.new(current_cells[1] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[1])),
							Condition.new(new_cells[0] - player_position, Globals.EMPTY_CELL),
							Condition.new(new_cells[1] - player_position, Globals.EMPTY_CELL)
							]
						var correct_cell = map.find_cell(player_position, conditions)
						if correct_cell != null:
							move_to_cell(correct_cell)
				Vector3i.DOWN:
					if map.is_cell_empty(new_cells[0]) and map.is_cell_empty(new_cells[1]):
						var conditions : Array[Condition] = [
							Condition.new(current_cells[0] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[0])),
							Condition.new(current_cells[1] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[1])),
							Condition.new(new_cells[0] - player_position, Globals.GROUND_CELLS)
							]
						var correct_cell = map.find_cell(player_position, conditions)
						if correct_cell != null:
							move_to_cell(correct_cell)
						else:
							conditions = [
							Condition.new(current_cells[0] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[0])),
							Condition.new(current_cells[1] - player_position, Globals.EMPTY_CELL, map.is_cell_visible(current_cells[1])),
							Condition.new(new_cells[1] - player_position, Globals.GROUND_CELLS)
							]
							correct_cell = map.find_cell(player_position, conditions)
							if correct_cell != null:
								move_to_cell(correct_cell)
				
		3:
			print("This never happens.")
			# This happens, like, never.
	return

func _visibility_change(old_cells : Array[Vector3i], new_cells : Array[Vector3i]) -> float:
	var old_visibility := 0.0
	for cell in old_cells:
		if map.is_cell_visible(cell):
			old_visibility += 1
		else:
			old_visibility -= 1
	old_visibility /= old_cells.size()
	var new_visibility := 0.0
	for cell in new_cells:
		if map.is_cell_visible(cell):
			new_visibility += 1
		else:
			new_visibility -= 1
	new_visibility /= new_cells.size()
	return new_visibility - old_visibility
