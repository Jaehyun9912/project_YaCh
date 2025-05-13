class_name UpperPanel extends Control

@onready var title := $VBoxContainer/TextType
@onready var info := $VBoxContainer/Detail

@onready var timer := $Timer

func set_panel(Title: String, Info: String):
	title.text = Title
	info.text = Info
	
func set_panel_with_time(Title: String, Info: String, wait):
	timer.timeout.emit()
	
	visible = true
	set_panel(Title, Info)
	
	timer.start(wait)
	await timer.timeout
	
	visible = false
