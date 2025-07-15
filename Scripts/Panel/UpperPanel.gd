class_name UpperPanel extends Control

@onready var title := $VBoxContainer/TextType
@onready var info := $VBoxContainer/Detail

@onready var timer := $Timer

# 패널의 정보 설정
func set_panel(Title: String, Info: String):
	title.text = Title
	info.text = Info
	
# 일정 시간동안만 표시
func set_panel_with_time(Title: String, Info: String, wait):
	timer.timeout.emit()
	
	visible = true
	set_panel(Title, Info)
	
	timer.start(wait)
	await timer.timeout
	
	visible = false
