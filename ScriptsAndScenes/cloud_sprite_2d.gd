extends Sprite2D

@export var textures: Array[Texture] = []

#const SPEED : float = 0.2
const SPEED : float = 50
@onready var marker_2d_stop = $"../../Marker2DStop"
@onready var marker_2d_start = $".."
var scale_comp : float

func _ready():
	randomize()
	var clouds = textures
	var picked_cloud = clouds[randi() % clouds.size()]
	texture = picked_cloud
	#scale_comp = (randi() % 3 + 8) * 0.1
	#scale = Vector2(scale_comp, scale_comp)
	#modulate.a = scale_comp - 0.3

func _physics_process(delta):
	#position.x -= SPEED * scale_comp * delta
	position.x -= SPEED * delta
	if position.x < (marker_2d_stop.position.x - marker_2d_start.position.x):
		queue_free()
