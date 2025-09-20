extends TextureRect
# BaseButton을 상속받아야하는데 모르고 TextureRect를 상속받은 상태에서 구현했습니다.
class_name RoundButton

@export var default_color := Color(1, 1, 1)
@export var hover_color := Color(0.5, 0.5, 0.5)
@export var click_color := Color(0.3, 0.3, 0.3)
@export var disable_color := Color(0.9, 0.9, 0.9)

@export var button_text: String
@export var font_size := 14

@onready var label = $Label as Label
@onready var init_text = button_text

func _ready():
	label.text = button_text
	label.add_theme_font_size_override("font_size", font_size)
	disabled = init_disabled
	
#func _init():
	#label.text = button_text

# 버튼 활성화 비활성화 
@export var init_disabled = false
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

var is_mouse_inside = false

# 버튼을 눌렀을 때 발동하는 시그널 
signal button_down()

# 버튼을 뗐을 때 발동하는 시그널
signal button_up()

# 버튼을 뗏을 때 마우스 위치가 버튼 위에 있다면 발동하는 시그널
signal button_clicked()

func set_text(text):
	label.text = text
func reset_text():
	label.text = init_text

func _on_button_mouse_entered():
	
	if disabled == true:
		return
	
	is_mouse_inside = true;
	self_modulate = hover_color

func _on_button_mouse_exited():
	if disabled == true:
		return
	
	is_mouse_inside = false;
	self_modulate = default_color

func _on_button_button_up():
	
	if disabled == true:
		return
		
	self_modulate = default_color
	button_up.emit()
	
	if is_mouse_inside:
		button_clicked.emit()

func _on_button_button_down():
	
	if disabled == true:
		return
	
	self_modulate = click_color
	button_down.emit()
