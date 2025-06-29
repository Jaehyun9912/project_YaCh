class_name ResultPanel extends Control

signal check_button_pressed

func _ready():
	visible = false

# 패널 텍스트 설정 
func set_panel(title_text, subtitle_text = "", info_text = ""):
	visible = true
	if subtitle_text == "" and info_text == "":
		set_text($ColorRect/SingleTitle, title_text)
	else:
		set_text($ColorRect/Title, title_text)
		set_text($ColorRect/SubTitle, subtitle_text)
		set_text($ColorRect/Info, info_text)
	

func set_text(panel, txt):
	panel.text = txt
	panel.visible = true

func _on_button_pressed():
	check_button_pressed.emit()
