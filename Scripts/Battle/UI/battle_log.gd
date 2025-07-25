class_name BattleLog extends Control

@onready var vcontainer = $ColorRect/ColorRect/ScrollContainer/VBoxContainer
@onready var scroll = $ColorRect/ColorRect/ScrollContainer as ScrollContainer
@onready var lab_setting = load("res://Objects/UI/Battle/log_label_settings.tres")

func add_log(info: String):
	var lab = Label.new()
	lab.text = info
	lab.label_settings = lab_setting
	vcontainer.add_child(lab)

func enable_panel():
	visible = true
	
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_exit_button_pressed():
	visible = false
