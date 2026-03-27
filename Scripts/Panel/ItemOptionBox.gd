extends Control
class_name ActionBox

signal on_clicked

func _ready():
	$"Button".pressed.connect(press)

# f = 함수, 해당 버튼 클릭시 실행될 함수 설정
func set_action(f, button_name: String):
	on_clicked.connect(f)
	$"Button".text = button_name
	
func press():
	on_clicked.emit()
