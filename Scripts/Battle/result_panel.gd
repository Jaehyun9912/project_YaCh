class_name ResultPanel extends Control

func _ready():
	visible = false

# 패널 텍스트 설정 
func set_panel(title_text, subtitle_text = "", info_text = ""):
	visible = true
	$ColorRect/Title.text = title_text
	$ColorRect/Subtitle.text = subtitle_text
	$ColorRect/Info.text = info_text
	
	if subtitle_text == "" and info_text == "":
		$ColorRect.size.y = 54
	else:
		$ColorRect.size.y = 204

