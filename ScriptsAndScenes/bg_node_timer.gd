extends Timer

@onready var cloud_node = preload("res://ScriptsAndScenes/cloud_sprite_2d.tscn")
@onready var marker_2d_start: Marker2D = $"../Marker2DStart"

const CLOUDS_SPAWNED_ON_READY : int = 7

func _ready() -> void:
	var screen_size : Vector2i = get_viewport().size
	for i in CLOUDS_SPAWNED_ON_READY:
		var cloud_instance = cloud_node.instantiate()
		@warning_ignore("integer_division")
		cloud_instance.position.y = randi_range(0, screen_size.y / 2)
		@warning_ignore("narrowing_conversion")
		cloud_instance.position.x = randi_range(0, marker_2d_start.position.x)
		add_sibling.call_deferred(cloud_instance)

func _on_timeout():
	var cloud_instance = cloud_node.instantiate()
	var screen_height : int = get_viewport().size.y
	
	add_sibling(cloud_instance)
	@warning_ignore("integer_division")
	cloud_instance.position.y = randi_range(0, screen_height / 2)
	cloud_instance.position.x = marker_2d_start.position.x
