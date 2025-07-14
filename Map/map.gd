extends GridMap
class_name Map

const PLAYER_SCENE = preload("res://player.tscn")
const DOOR_SCENE = preload("res://door.tscn")


func _ready() -> void:
	var used_cells = get_used_cells()
	for cell_position in used_cells:
		if get_cell_item(cell_position) == mesh_library.find_item_by_name("PlayerMarker"):
			var player = PLAYER_SCENE.instantiate()
			add_child(player)
			player.position = map_to_local(cell_position)
		if get_cell_item(cell_position) == mesh_library.find_item_by_name("Door"):
			var door = DOOR_SCENE.instantiate()
			add_child(door)
			door.position = map_to_local(cell_position)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("rotate_left"):
		rotate(Vector3.UP, PI/2)
	if Input.is_action_just_pressed("rotate_right"):
		rotate(Vector3.UP, -PI/2)
