extends Control

var _cut_scene:
	get:
		return $"TextureRect" as TextureRect

func set_image(texture : Texture2D):
	_cut_scene.texture = texture

