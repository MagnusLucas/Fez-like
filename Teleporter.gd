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
			_handle_hiding_one_new(new_cells[0], player_position)
		2:
			_handle_hiding_two_new(current_cells, new_cells, player_position)
		3:
			_handle_hiding_three_new(current_cells, new_cells, player_position)
	return

func _handle_hiding_one_new(new_cell : Vector3i, 
		player_position : Vector3i) -> void:
	
	var direction : Vector3i = new_cell - player_position
	var direction_local := Vector3i(Vector3(direction) * player.basis)
	
	var current_condition : Array[Condition] = _get_current_conditions(
			[player_position], player_position)
	#print("Simple hiding ", Condition.vec_to_string(direction_local))
	match direction_local:
		Vector3i.UP:
			if _wont_collide([new_cell]):
				var conditions : Array[Condition] = current_condition
				conditions.append(Condition.new("UP", Globals.EMPTY_CELL, true))
				var correct_cell = map.find_cell(player_position, conditions)
				move_to_cell(correct_cell)
		Vector3i.DOWN:
			if _wont_collide([new_cell]):
				var conditions : Array[Condition] = current_condition
				conditions.append(Condition.new("DOWN", Globals.GROUND_CELLS))
				if !move_if_possible(player_position, conditions):
					conditions = current_condition
					conditions.append(
							Condition.new("DOWN", Globals.EMPTY_CELL, true))
					move_if_possible(player_position, conditions)
		Vector3i.LEFT, Vector3i.RIGHT:
			# Disallow going behind stuff, so 
			# - try tp on ground in front
			# - tp collide
			# - wait tp collide sucks
			# - actually just manually stop the player
			# - this still sucks...
			if _wont_collide([new_cell]):
				var conditions : Array[Condition] = current_condition
				conditions += [
						Condition.new("DOWN", Globals.GROUND_CELLS),
						Condition.new(direction_local, Globals.EMPTY_CELL, true)]
				if !move_if_possible(player_position, conditions):
					conditions = current_condition
					conditions += [
						Condition.new(direction_local, Globals.EMPTY_CELL, true),
						Condition.new(direction_local + Vector3i.DOWN, 
							Globals.GROUND_CELLS)
						]
					if !move_if_possible(player_position, conditions):
						_force_stop_player()
			else:
				var conditions : Array[Condition] = current_condition
				conditions += [
						Condition.new("DOWN", Globals.GROUND_CELLS),
						Condition.new(direction_local, Globals.EMPTY_CELL, true)]
				if !move_if_possible(player_position, conditions):
					conditions = current_condition
					conditions += [
						Condition.new(direction_local, Globals.EMPTY_CELL, true),
						Condition.new(direction_local + Vector3i.DOWN,
							Globals.GROUND_CELLS)
					]
					move_if_possible(player_position, conditions)

func _handle_hiding_two_new(current_cells : Array[Vector3i],
		new_cells : Array[Vector3i], player_position : Vector3i) -> void:
	var direction : Vector3i = _get_new_direction(new_cells, player_position)
	var direction_local := Vector3i(Vector3(direction) * player.basis)
	
	var current_conditions : Array[Condition] = _get_current_conditions(
			current_cells, player_position
	)
	
	#print("Two-cell hiding ", Condition.vec_to_string(direction_local))
	match direction_local:
		Vector3i.UP, Vector3i.LEFT, Vector3i.RIGHT:
			var conditions : Array[Condition] = current_conditions
			conditions += [
				Condition.new(to_local(new_cells[0] - player_position),
					Globals.EMPTY_CELL),
				Condition.new(to_local(new_cells[1] - player_position),
					Globals.EMPTY_CELL)
			]
			var correct_cell = map.find_cell(player_position, conditions)
			if correct_cell != null:
				# Check if the player is becoming fully invisible after tp
				#var future_cells : Array[Vector3i] = Globals.subtract_vector_from_each(directional_to_new, -correct_cell)
				#future_cells += Globals.subtract_vector_from_each(current_cells, player_position - Vector3i(correct_cell))
				#if _is_player_visibile(future_cells) != false:
					move_to_cell(correct_cell)
		Vector3i.DOWN:
			if _wont_collide(new_cells):
				var conditions : Array[Condition] = current_conditions
				conditions.append(Condition.new(
					to_local(new_cells[0] - player_position),
					Globals.GROUND_CELLS))
				
				if !move_if_possible(player_position, conditions):
					conditions = current_conditions
					conditions.append(Condition.new(
						to_local(new_cells[1] - player_position),
						Globals.GROUND_CELLS))
					move_if_possible(player_position, conditions)

func _handle_hiding_three_new(current_cells : Array[Vector3i],
		new_cells : Array[Vector3i], player_position : Vector3i) -> void:
	var direction : Vector3i = _get_new_direction(new_cells, player_position)
	var direction_local := Vector3i(Vector3(direction) * player.basis)
	print("Hiding ", Condition.vec_to_string(direction_local))

func _handle_no_visibility_change(current_cells : Array[Vector3i],
		new_cells : Array[Vector3i], player_position : Vector3i) -> void:
	# Keep on ground
	# Avoid walls
	
	# First figure out the case
	match new_cells.size():
		1:
			_handle_no_change_one_new(new_cells[0], player_position)
		2:
			_handle_no_change_two_new(current_cells, new_cells, player_position)
		3:
			_handle_no_change_three_new(current_cells, new_cells, player_position)
	return

func _handle_no_change_one_new(
		new_cell : Vector3i, player_position : Vector3i) -> void:
	var direction : Vector3i = new_cell - player_position
	var direction_local := Vector3i(Vector3(direction) * player.basis)
	
	var current_conditions : Array[Condition] = _get_current_conditions(
			[player_position], player_position)
	
	match direction_local:
		Vector3i.UP:
			if _will_collide([new_cell]):
				var conditions : Array[Condition] = current_conditions
				conditions.append(Condition.new("UP", Globals.EMPTY_CELL))
				
				var correct_cell = map.find_cell(player_position, conditions)
				move_to_cell(correct_cell)
		Vector3i.DOWN:
			if _wont_collide([new_cell]):
				var conditions : Array[Condition] = current_conditions
				conditions.append(Condition.new("DOWN", Globals.GROUND_CELLS))
				move_if_possible(player_position, conditions)
		Vector3i.LEFT, Vector3i.RIGHT:
			if _will_collide([new_cell]):
				var conditions : Array[Condition] = current_conditions
				conditions += [
					Condition.new("DOWN", Globals.GROUND_CELLS),
					Condition.new(direction_local, Globals.EMPTY_CELL, true)]
				if !move_if_possible(player_position, conditions):
					conditions = current_conditions
					conditions += [
						Condition.new(direction_local + Vector3i.DOWN, Globals.GROUND_CELLS),
						Condition.new(direction_local, Globals.EMPTY_CELL, true)]
					if !move_if_possible(player_position, conditions):
						_force_stop_player()

func _handle_no_change_two_new(current_cells : Array[Vector3i],
		new_cells : Array[Vector3i], player_position : Vector3i) -> void:
	var direction : Vector3i = _get_new_direction(new_cells, player_position)
	var direction_local := Vector3i(Vector3(direction) * player.basis)
	match direction_local:
		Vector3i.UP, Vector3i.LEFT, Vector3i.RIGHT:
			if _will_collide(new_cells):
				var conditions : Array[Condition] = _get_current_conditions(
						current_cells, player_position)
				conditions += [
					Condition.new(to_local(new_cells[0] - player_position),
						Globals.EMPTY_CELL),
					Condition.new(to_local(new_cells[1] - player_position),
						Globals.EMPTY_CELL)
					]
				move_if_possible(player_position, conditions)
		
		Vector3i.DOWN:
			if _wont_collide(new_cells):
				var conditions : Array[Condition] = _get_current_conditions(
						current_cells, player_position)
				conditions.append(
					Condition.new(to_local(new_cells[0] - player_position),
						Globals.GROUND_CELLS))
				
				if !move_if_possible(player_position, conditions):
					conditions =  _get_current_conditions(
							current_cells, player_position)
					conditions.append(
						Condition.new(to_local(new_cells[1] - player_position),
							Globals.GROUND_CELLS))
					move_if_possible(player_position, conditions)

func _handle_no_change_three_new(current_cells : Array[Vector3i],
		new_cells : Array[Vector3i], player_position : Vector3i) -> void:
	var direction : Vector3i = _get_new_direction(new_cells, player_position)
	var direction_local := Vector3i(Vector3(direction) * player.basis)
	print("No change ", Condition.vec_to_string(direction_local))

func _visibility_change(old_cells : Array[Vector3i], 
		new_cells : Array[Vector3i]) -> float:
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

func _get_current_conditions(current_cells : Array[Vector3i],
		player_position : Vector3i) -> Array[Condition]:
	var result : Array[Condition]
	for cell in current_cells:
		result.append(
				Condition.new(cell - player_position, Globals.EMPTY_CELL,
						map.is_cell_visible(cell)))
	return result

func _will_collide(new_cells : Array[Vector3i]) -> bool:
	for cell in new_cells:
		if !map.is_cell_empty(cell):
			return true
	return false

func _wont_collide(new_cells : Array[Vector3i]) -> bool:
	return !_will_collide(new_cells)

func _get_new_direction(new_cells : Array[Vector3i], 
		player_position : Vector3i) -> Vector3i:
	if new_cells.size() == 1:
		return new_cells[0] - player_position
	var directional_to_new : Array[Vector3i] = Globals.subtract_vector_from_each(new_cells, player_position)
	if new_cells.size() == 2:
		for cell in directional_to_new:
			if cell.length_squared() == 1:
				return cell
	if new_cells.size() == 3:
		for cell in directional_to_new:
			if cell.length_squared() == 2:
				return cell
	print_debug("There's a different amount of new cells than 1, 2, or 3. That's pretty bad.")
	print(directional_to_new)
	return Vector3i.ZERO

func _force_stop_player() -> void:
	var local_player_velocity = player.velocity * player.basis
	local_player_velocity.x = 0
	player.velocity = local_player_velocity * player.basis.inverse()

func move_if_possible(player_position : Vector3i, 
		conditions : Array[Condition]) -> bool:
	var correct_cell = map.find_cell(player_position, conditions)
	if correct_cell != null:
		move_to_cell(correct_cell)
		return true
	return false

func to_local(vector : Vector3i) -> Vector3i:
	return Vector3i((Vector3(vector) * player.basis).round())
