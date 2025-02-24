extends Control
class_name CharacterChoicePanel

@onready var hbox := $ColorRect/HBoxContainer
@onready var label := $ColorRect/Label
@onready var btn_theme = load("res://Objects/UI/Battle/button_theme.tres")
var buttons : Array

@onready var done_button := $ColorRect/Done

# 버튼 창 닫혔을 떄 
signal choice_end(index)

var need_choice := 0
var current_choice := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_active(false)
	#need_choice = 1
	#set_panel(3)

# 패널의 보임 여부 설정 
func set_active(onoff):
	var rect = $ColorRect as ColorRect
	rect.visible = onoff
	if onoff:
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
# 들어온 값만큼 버튼을 동적으로 생성 
func set_panel(btn_count):
	set_active(true)
	done_button.disabled = true
	for i in range(btn_count):
		var btn = Button.new()
		btn.size_flags_stretch_ratio = 1
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.theme = btn_theme
		btn.toggled.connect(self._on_button_pressed.bind(i))
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE

		hbox.add_child(btn)
		buttons.append(btn)
		
# 대상 버튼을 눌렀을 때 
func _on_button_pressed(toggled_on, i):
	#print(toggled_on, " ", i)
	# 버튼을 켰을 때 
	if toggled_on:
		current_choice += 1
		
		if current_choice == need_choice:
			for btn in buttons:
				if not btn.button_pressed:
					btn.disabled = true
	# 버튼을 껐을 때 
	else:
		if current_choice == need_choice:
			for btn in buttons:
				btn.disabled = false
		
		current_choice -= 1
	done_button.disabled = not current_choice == need_choice
	
# 버튼 다 지우기 
func reset_buttons():
	for i in buttons:
		i.queue_free()
	buttons.clear()
	label.visible = false

#  버튼의 개수, 선택해야하는 개수를 받아와 패널 생성 
func set_choice_panel(number: int, choice_count: int):
	
	# 만약 선택해야 하는 대상이 총 대상보다 많다면 전체 패널로 교체 
	if number <= choice_count:
		set_all_panel()
		return

	set_panel(number)
	
	print("target : ", choice_count)
	
	need_choice = choice_count
	current_choice = 0
	
# 대상 버튼 없이 텍스트만 설정하는 패널 
func set_label_panel(text):
	need_choice = 0
	current_choice = 0
	set_panel(0)
	done_button.disabled = false

	label.text = text
	label.visible = true

# 자기 자신에게 적용할 때 
func set_self_panel():
	set_label_panel("나에게 적용하기")
	
# 모두를 대상으로 적용할 때 
func set_all_panel():
	set_label_panel("모두를 대상으로 하기")

# 완료 버튼 눌렀을 때 
func _on_done_pressed():
	# 클릭한 버튼들의 인덱스를 모아서 반환 
	var clicked_index = []
	for i in range(len(buttons)):
		if buttons[i].button_pressed:
			clicked_index.append(i)
	choice_end.emit(clicked_index)
	reset_buttons()
	set_active(false)

# 취소 버튼 눌렀을 떄 
func _on_cancel_pressed():
	# 버튼 리셋하고 null 반환 
	reset_buttons()
	set_active(false)
	choice_end.emit(null)
