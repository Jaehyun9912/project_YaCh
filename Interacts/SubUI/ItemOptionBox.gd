extends Control
class_name ActionBox

signal Onclicked

func _ready():
	$"Button".pressed.connect(press)

# f = 함수
func set_action(f, name:String):
	Onclicked.connect(f)
	$"Button".text = name
	
func press():
	Onclicked.emit()
