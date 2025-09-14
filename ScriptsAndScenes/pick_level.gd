extends Button
class_name  LevelButton

@export var level : PackedScene

func _on_pressed() -> void:
	var map_instance = level.instantiate()
	
	var game_scene = Game.instantiate(map_instance)
	
	get_tree().root.add_child(game_scene)
	get_node("/root/Menu").queue_free()
