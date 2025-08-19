@tool
extends EditorPlugin

var gme : GridMapEditorPlugin

var font : Font

var debug : bool = true
var debug_label : Label

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	var root = get_editor_interface().get_resource_filesystem().get_node("/root")
	gme = root.find_children("", "GridMapEditorPlugin", true, false)[0]
	
	var output_label : Label = Label.new()
	font = output_label.get_theme_font("font")
	output_label.free()
	
	if debug:
		debug_label = preload("res://addons/gridmap_coordinate_shower/coordinate_label.tscn").instantiate()
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, debug_label)
	
	set_force_draw_over_forwarding_enabled()

func _exit_tree() -> void:
	if debug:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, debug_label)
		debug_label.free()

func _handles(object: Object) -> bool:
	return object is GridMap

func _make_visible(visible: bool) -> void:
	if debug:
		if visible:
			debug_label.show()
		else:
			debug_label.hide()

func _get_selection_coordinate_string() -> String:
	if !gme.has_selection():
		return ""
	else:
		var selection : AABB = gme.get_selection()
		if selection.size == Vector3.ZERO:
			return str(selection.position)
		else:
			return str(selection.position) + " : " + str(selection.end)

func _get_hover_coordinates_string() -> String:
	var mouse_position = EditorInterface.get_editor_viewport_3d(0).get_mouse_position()
	
	# Here some check whether it's in viewport?
	
	
	return str(mouse_position)

func _process(delta: float) -> void:
	if debug:
		debug_label.text = _get_selection_coordinate_string()

func _forward_3d_force_draw_over_viewport(overlay : Control):
	overlay.draw_string_outline(font, Vector2(5, overlay.size.y - 5) ,_get_hover_coordinates_string(), 
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 2, Color.BLACK)
	overlay.draw_string(font, Vector2(5, overlay.size.y - 5) ,_get_hover_coordinates_string(), 
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	
func _forward_3d_gui_input(camera, event):
	if event is InputEventMouseMotion:
		# Redraw viewport when cursor is moved.
		update_overlays()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS
