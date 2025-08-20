@tool
extends EditorPlugin

const MAIN_SPLIT = "@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockHSplitMain"
const BOTTOM_LOCATION = MAIN_SPLIT + "/@VBoxContainer@26/DockVSplitCenter/@EditorBottomPanel@7930"
const GRIDMAP_LOCATION = BOTTOM_LOCATION + "/@VBoxContainer@7915/@GridMapEditor@21369"

const SPINBOX_LOCATION = GRIDMAP_LOCATION + "/@HBoxContainer@21316/@SpinBox@21356"

# But it's empty...
const AXIS_POPUP_LOCATION = GRIDMAP_LOCATION + "/@HBoxContainer@21316/@MenuButton@21364"

var gme : GridMapEditorPlugin
var output_label : Label
var viewport_3d : SubViewport
var spinbox : SpinBox


func _enter_tree() -> void:
	# For getting gridmap and its selection
	var root = get_editor_interface().get_resource_filesystem().get_node("/root")
	gme = root.find_children("", "GridMapEditorPlugin", true, false)[0]
	
	# For printing output in viewport
	output_label = preload("res://addons/gridmap_coordinate_shower/coordinate_label.tscn").instantiate()
	viewport_3d = EditorInterface.get_editor_viewport_3d(0)
	viewport_3d.add_child(output_label)
	
	# For retrieving floor value of gridmap editor
	spinbox = EditorInterface.get_base_control().get_node(SPINBOX_LOCATION)


func _process(delta: float) -> void:
	output_label.text = _get_hover_coordinates_string()


func _handles(object: Object) -> bool:
	return object is GridMap


func _make_visible(visible: bool) -> void:
	if visible:
		output_label.show()
	else:
		output_label.hide()


func _exit_tree() -> void:
	viewport_3d.remove_child(output_label)
	output_label.free()


#func _get_selection_coordinate_string() -> String:
	#if !gme.has_selection():
		#return "No active selection"
	#else:
		#var selection : AABB = gme.get_selection()
		#if selection.size == Vector3.ZERO:
			#return str(selection.position)
		#else:
			#return str(selection.position) + " : " + str(selection.end)


func _get_gridmap_plane_intersection(plane_basis : Vector3, gridmap : GridMap, 
		ray_origin : Vector3, ray_normal : Vector3) -> Variant:
	
	var gridmap_transform : Transform3D = gridmap.transform
	var plane := Plane(plane_basis, 
			gridmap_transform.origin + plane_basis * spinbox.value * gridmap.cell_size)
	
	var intersection_point : Variant = plane.intersects_ray(ray_origin, ray_normal)
	if intersection_point:
		return gridmap.local_to_map(intersection_point - gridmap_transform.origin)
	else:
		return null


func _format_intersection_string(axis : String, coordinates : Variant) -> String:
	if coordinates != null:
		return axis + " " + str(coordinates) + "   "
	else:
		return axis + " () "


func _get_hover_coordinates_string() -> String:
	var mouse_position = viewport_3d.get_mouse_position()
	var current_gridmap = gme.get_current_grid_map()
	
	if current_gridmap and viewport_3d.get_visible_rect().has_point(mouse_position):
		var gridmap_transform : Transform3D = current_gridmap.transform
		var camera = viewport_3d.get_camera_3d()
		var result_string : String = ""
		
		# TODO: Fix this to print only currently edited axis
		# Didn't find a way to read it yet
		# But feel free to comment out any axis below as needed
		
		result_string += _format_intersection_string("X", _get_gridmap_plane_intersection(
				gridmap_transform.basis.x, current_gridmap,
				camera.project_ray_origin(mouse_position), camera.project_ray_normal(mouse_position)
		))
		result_string += _format_intersection_string("Y", _get_gridmap_plane_intersection(
				gridmap_transform.basis.y, current_gridmap,
				camera.project_ray_origin(mouse_position), camera.project_ray_normal(mouse_position)
		))
		result_string += _format_intersection_string("Z", _get_gridmap_plane_intersection(
				gridmap_transform.basis.z, current_gridmap,
				camera.project_ray_origin(mouse_position), camera.project_ray_normal(mouse_position)
		))
		
		return result_string
	
	return ""
