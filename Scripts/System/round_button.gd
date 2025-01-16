extends TextureRect
# BaseButton을 상속받아야하는데 모르고 TextureRect를 상속받은 상태에서 구현했습니다.
class_name RoundButton

# 버튼 시그널 별 함수가 아닌 하나의 함수에서 관리하기 위한 넘버
@export var button_number: int

@export var hover_color := Color(0.5, 0.5, 0.5)
@export var click_color := Color(0.3, 0.3, 0.3)
@export var disable_color := Color(0.9, 0.9, 0.9)

# 버튼 활성화 비활성화 여부
var disabled = false :
	get:
		return disabled
	set(value):
		if lock_disable == true: return
		disabled = value
		if value == true:
			self_modulate = disable_color
		else:
			self_modulate = Color(1, 1, 1)
# 활성화 시 disable이 변경되지 않음
var lock_disable = false

# 마우스로 버튼을 눌렀을 때 발동하는 시그널 
signal button_down(number: int)

func _on_button_mouse_entered():
	
	if disabled == true:
		return
	
	self_modulate = hover_color

func _on_button_mouse_exited():
	if disabled == true:
		return
	
	self_modulate = Color(1, 1, 1)

func _on_button_button_up():
	
	if disabled == true:
		return
		
	self_modulate = hover_color

func _on_button_button_down():
	
	if disabled == true:
		return
	
	self_modulate = click_color
	button_down.emit(button_number)
