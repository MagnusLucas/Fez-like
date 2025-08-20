@tool
extends EditorPlugin

var gme : GridMapEditorPlugin

var debug_label : Label

const BOTTOM_LOCATION = "@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockHSplitMain/@VBoxContainer@26/DockVSplitCenter/@EditorBottomPanel@7930"
const GRIDMAP_LOCATION = BOTTOM_LOCATION + "/@VBoxContainer@7915/@GridMapEditor@21369"
const SPINBOX_LOCATION = GRIDMAP_LOCATION + "/@HBoxContainer@21316/@SpinBox@21356"

var spinbox : SpinBox
var viewport_3d : SubViewport

func _enter_tree() -> void:
	# For getting selection
	var root = get_editor_interface().get_resource_filesystem().get_node("/root")
	gme = root.find_children("", "GridMapEditorPlugin", true, false)[0]
	
	# For printing output in viewport
	debug_label = preload("res://addons/gridmap_coordinate_shower/coordinate_label.tscn").instantiate()
	viewport_3d = EditorInterface.get_editor_viewport_3d(0)
	viewport_3d.add_child(debug_label)
	
	# For retrieving floor value of gridmap editor
	spinbox = EditorInterface.get_base_control().get_node(SPINBOX_LOCATION)
	

func _exit_tree() -> void:
	viewport_3d.remove_child(debug_label)
	debug_label.free()

func _handles(object: Object) -> bool:
	return object is GridMap

func _make_visible(visible: bool) -> void:
	if visible:
		debug_label.show()
	else:
		debug_label.hide()

func _get_selection_coordinate_string() -> String:
	if !gme.has_selection():
		return "No active selection"
	else:
		var selection : AABB = gme.get_selection()
		if selection.size == Vector3.ZERO:
			return str(selection.position)
		else:
			return str(selection.position) + " : " + str(selection.end)

func _get_hover_coordinates_string() -> String:
	var viewport_position : Vector2 = viewport_3d.get_parent().global_position
	
	var mouse_position = viewport_3d.get_mouse_position()
	var current_gridmap = gme.get_current_grid_map()
	
	if current_gridmap:
		return str(current_gridmap.position)
	
	return " "

func _process(delta: float) -> void:
	debug_label.text = _get_hover_coordinates_string()
