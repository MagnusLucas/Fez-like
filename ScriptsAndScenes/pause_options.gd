extends VBoxContainer


func _on_resume_pressed() -> void:
	$"../..".hide()
	get_tree().paused = false


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_node("/root/Game").queue_free()
	get_tree().change_scene_to_file("res://ScriptsAndScenes/menu.tscn")
