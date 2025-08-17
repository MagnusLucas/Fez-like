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

func _ready() -> void:
	_instantiate_scripted_scenes()
	if camera_follows_player:
		var player : Player = find_child("Player", false, false)
		$CameraOrigin.player = player
		
		$CameraOrigin.connect("camera_rotation_started", player.stop_movement)
		$CameraOrigin.connect("camera_rotation_finished", player.update_rotation)

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

func cell_in_view(cell_position : Vector3i) -> bool:
	return true
