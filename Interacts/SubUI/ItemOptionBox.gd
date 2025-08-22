extends Control
class_name ActionBox

signal on_clicked

func _ready():
	$"Button".pressed.connect(press)

# f = 함수
func set_action(f, name:String):
	on_clicked.connect(f)
	$"Button".text = name
	
func press():
	on_clicked.emit()
