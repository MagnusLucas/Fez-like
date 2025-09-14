extends SubViewport

#@onready var _2d_bg_sub_viewport = $"."
#@onready var mesh_instance_3d = $"../CameraOrigin/MeshInstance3D"
#@onready var sky_sprite_3d = $"../CameraOrigin/SkySprite3D"

func _ready():
	size = get_parent().get_viewport().size
	# Clear viewport.
	#_2d_bg_sub_viewport.set_clear_mode(SubViewport.CLEAR_MODE_ALWAYS)
	# Set viewport sprite size.
	#sky_sprite_3d.size = size
	# Retrieve the texture and set it to the viewport sprite.
	#sky_sprite_3d.texture = get_texture()
	#mesh_instance_3d.material_override = get_texture()
