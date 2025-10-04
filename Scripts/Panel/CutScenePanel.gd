extends Control

signal on_exit

var _cut_scene:
	get:
		return $"TextureRect" as TextureRect

# meta데이터에서 그림 받아오기 또는 그림 파일 경로 받아와서 표시하기
func initialize(data: Dictionary):
	print("CutScene")
	pass


# 개별적으로 설정하지 않으면 view매니저에서 이미지 가져오기 및 세팅
func _ready():
	pass


# 컷신 패널 일반적인 세팅 방법
func set_cutScene(texture: Texture2D):
	_cut_scene.texture = texture


func onClicked(event: InputEvent):
	if event.is_pressed():
		print("Clicked")
		on_exit.emit()
