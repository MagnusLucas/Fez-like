extends Sprite2D

@export var textures: Array[Texture] = []

var marker_2d_stop: Marker2D

#const SPEED : float = 0.2
const BASIC_SPEED : float = 50
const SPEED_VARIABILITY : float = 0.5

var speed
var scale_comp : float


func _ready():
	var clouds = textures
	var picked_cloud = clouds[randi() % clouds.size()]
	texture = picked_cloud
	
	marker_2d_stop = get_parent().find_child("Marker2DStop")
	
	speed = BASIC_SPEED * randf_range(1 - SPEED_VARIABILITY, 1 + SPEED_VARIABILITY)
	#scale_comp = (randi() % 3 + 8) * 0.1
	#scale = Vector2(scale_comp, scale_comp)
	#modulate.a = scale_comp - 0.3

func _physics_process(delta):
	#position.x -= SPEED * scale_comp * delta
	position.x -= speed * delta
	if position.x < marker_2d_stop.position.x:
		queue_free()
