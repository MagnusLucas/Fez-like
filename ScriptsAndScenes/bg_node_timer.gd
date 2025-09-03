extends Timer

@onready var cloud_node = preload("res://ScriptsAndScenes/cloud_sprite.tscn")
@onready var marker_3d = $".."

func _on_timeout():
	var cloud_instance = cloud_node.instantiate()
	marker_3d.add_child(cloud_instance)
	randomize()
	cloud_instance.position.y += randi() % 20 - 10
