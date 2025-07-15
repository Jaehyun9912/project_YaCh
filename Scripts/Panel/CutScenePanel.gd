extends Control

var _cut_scene:
	get:
		return $"TextureRect" as TextureRect

var timer : float = 0


# 개별적으로 설정하지 않으면 view매니저에서 이미지 가져오기 및 세팅
func _ready():
	if timer <=0:
		set_cutScene(ViewManager.cur_meta_data["Image"] as Texture2D,1)	


# 컷신 패널 일반적인 세팅 방법
func set_cutScene(texture : Texture2D, time =0.1):
	_cut_scene.texture = texture
	timer = time

func _process(delta):
	if timer>0:
		timer-=delta

func onClicked(event:InputEvent):
	if event.is_pressed() && timer <= 0:
		print("Clicked")
		ViewManager.erase_panel(self)

