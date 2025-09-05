extends Sprite3D

@export var textures: Array[Texture] = []

#const SPEED : float = 0.2
const SPEED : float = 2
@onready var marker_3d_stop = $"../../Marker3DStop"
@onready var marker_3d_start = $".."
var scale_comp : float

func _ready():
	#position.z = get_parent().position.z
	randomize()
	var clouds = textures
	var picked_cloud = clouds[randi() % clouds.size()]
	texture = picked_cloud
	scale_comp = (randi() % 3 + 8) * 0.1
	#scale = Vector3(scale_comp, scale_comp, scale_comp)
	scale = Vector3(8,8,8)
	modulate.a = scale_comp - 0.3

func _process(delta):
	position.x -= SPEED * scale_comp * delta
	if position.x < (marker_3d_stop.position.x - marker_3d_start.position.x):
		queue_free()
