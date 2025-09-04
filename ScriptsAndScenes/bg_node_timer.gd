extends Timer

@onready var cloud_node = preload("res://ScriptsAndScenes/cloud_sprite_2d.tscn")
@onready var marker_2d_start = $".."

func _on_timeout():
	var cloud_instance = cloud_node.instantiate()
	marker_2d_start.add_child(cloud_instance)
	randomize()
	cloud_instance.position.y += randi() % 200 - 100
