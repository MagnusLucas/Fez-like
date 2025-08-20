@tool
extends EditorPlugin

var gme : GridMapEditorPlugin

var font : Font

const DEBUG : bool = true
var debug_label : Label

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	var root = get_editor_interface().get_resource_filesystem().get_node("/root")
	gme = root.find_children("", "GridMapEditorPlugin", true, false)[0]
	
	var output_label : Label = Label.new()
	font = output_label.get_theme_font("font")
	output_label.free()
	
	if DEBUG:
		debug_label = preload("res://addons/gridmap_coordinate_shower/coordinate_label.tscn").instantiate()
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, debug_label)
	
	set_force_draw_over_forwarding_enabled()

func _exit_tree() -> void:
	if DEBUG:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, debug_label)
		debug_label.free()

func _handles(object: Object) -> bool:
	return object is GridMap

func _make_visible(visible: bool) -> void:
	if DEBUG:
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
	var viewport : SubViewport = EditorInterface.get_editor_viewport_3d(0)
	var viewport_position : Vector2 = viewport.get_parent().global_position
	
	var mouse_position = viewport.get_mouse_position()
	var current_gridmap = gme.get_current_grid_map()
	
	var coordinates : Vector3i
	
	#XD
	# emit click, get selection, then undo
	if viewport.get_visible_rect().has_point(mouse_position) and current_gridmap:
		var mouse_was_pressed : bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var had_selection : bool = gme.has_selection()
		var current_selection : AABB
		
		if mouse_was_pressed:
			var release = InputEventMouseButton.new()
			release.pressed = false
			release.button_index = MOUSE_BUTTON_LEFT
			
			current_selection = gme.get_selection()
			Input.parse_input_event(release)
			#gme.clear_selection()
		
		var click = InputEventMouseButton.new()
		click.global_position = viewport_position + mouse_position
		click.position = viewport_position + mouse_position
		click.pressed = true
		click.button_index = MOUSE_BUTTON_LEFT
		Input.parse_input_event(click)
		
		var release = click.duplicate()
		release.pressed = false
		Input.parse_input_event(release)
		
		coordinates = gme.get_selection().position
		#print(coordinates)
		
		var undo : InputEventAction = InputEventAction.new()
		undo.action = "ui_undo"
		undo.pressed = true
		Input.parse_input_event(undo)
		
		#if had_selection:
			#var press = click.duplicate()
			#Input.parse_input_event(press)
			#
			#gme.set_selection(current_selection.position.min(coordinates),
				#current_selection.position.min(coordinates) + abs(current_selection.position - Vector3(coordinates)))
		
		return str(coordinates)
	
	return " "

func _process(delta: float) -> void:
	update_overlays()
	if DEBUG:
		debug_label.text = _get_selection_coordinate_string()

func _forward_3d_force_draw_over_viewport(overlay : Control):
	overlay.draw_string_outline(font, Vector2(5, overlay.size.y - 5) , _get_hover_coordinates_string(), 
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 2, Color.BLACK)
	overlay.draw_string(font, Vector2(5, overlay.size.y - 5) , _get_hover_coordinates_string(), 
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	
