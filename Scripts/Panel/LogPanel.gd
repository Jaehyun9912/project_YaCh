extends Control

var container:
	get:
		return $ColorRect/ScrollContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	var talk_panel = ViewManager.push_panel("TextPanel") as TextPanel
	talk_panel.init(ViewManager.now_map_name)
	talk_panel.text_updated.connect(record_text)
	talk_panel.text_ended.connect(_go_main_scene)
	
	
	
	pass # Replace with function body.




func record_text(speaker,words) -> void:
	var text = speaker + " : " + words
	var text_box = RichTextLabel.new()
	text_box.fit_content = true
	text_box.text = text
	container.add_child(text_box)
	
	# 스크롤 바 아래로 고정하기
	var scroll = container.get_parent() as ScrollContainer
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
	
# 디버그용
func _go_main_scene():
	ViewManager.load_world("TestCountry","ChoicePanel","TestCountry")
