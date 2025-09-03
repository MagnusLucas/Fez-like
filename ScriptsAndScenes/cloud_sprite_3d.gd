extends Sprite3D

@export var textures: Array[Texture] = []

#const SPEED : float = 0.5
const SPEED : float = 4
@onready var marker_3d_stop = $"../../Marker3DStop"
@onready var marker_3d_start = $".."

func _ready():
	#position.z = get_parent().position.z
	randomize()
	var clouds = textures
	var picked_cloud = clouds[randi() % clouds.size()]
	texture = picked_cloud
	var scale_comp = randi() % 4 + 7 * 0.1
	scale = Vector3(scale_comp, scale_comp, scale_comp)
	modulate.a = scale_comp

func _process(delta):
	position.x -= SPEED * delta
	if position.x < (marker_3d_stop.position.x - marker_3d_start.position.x):
		queue_free()
