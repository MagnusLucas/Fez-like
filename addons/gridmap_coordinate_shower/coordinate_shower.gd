@tool
extends GridMapEditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

func _process(delta: float) -> void:
	print(str(get_selected_cells()))
