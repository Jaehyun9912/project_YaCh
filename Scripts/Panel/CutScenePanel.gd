extends Control

var _cut_scene:
	get:
		return $"TextureRect" as TextureRect

func set_image(texture : Texture2D):
	
	_cut_scene.texture = texture

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
