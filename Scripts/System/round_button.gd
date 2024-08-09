extends TextureRect

# 버튼 시그널 별 함수가 아닌 하나의 함수에서 관리하기 위한 넘버
@export var ButtonNumber: int

@export var HoverColor := Color(0.5, 0.5, 0.5)
@export var ClickColor := Color(0.3, 0.3, 0.3)

var disabled = false

signal button_down(number: int)

func _on_button_mouse_entered():
	
	if disabled == true:
		return
	
	self.modulate = HoverColor

func _on_button_mouse_exited():
	self.modulate = Color(1, 1, 1)

func _on_button_button_up():
	
	if disabled == true:
		return
		
	self.modulate = HoverColor

func _on_button_button_down():
	
	if disabled == true:
		return
	
	self.modulate = ClickColor
	button_down.emit(ButtonNumber)
