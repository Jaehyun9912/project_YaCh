extends Control

var file_name : String
var data
var talk_data

var name_text:
	get:
		return $ColorRect/NPC_name
var words_text:
	get:
		return $ColorRect/Text


func _ready():
	load_data("TestTalk")
	load_text_block("Start")
	pass # Replace with function body.

# 대사 진행도
var text_num

# file Name으로 텍스트 데이터 불러오기
func load_data(file_name : String) -> void:
	data = DataManager.get_data("Conversation/" + file_name)
	text_num = 0



func load_text() -> void:
	if talk_data.size() <= text_num:
		print("EOT")
		return
	var text_data = talk_data[text_num]
	
	var speaker = text_data["Name"]
	var words = text_data["Text"]
	var choice = null
	if text_data.has("Choice"):
		choice = text_data["Choice"]
		var panel = $Btns as BtnPanel
		panel.clear_buttons()
		panel.show()
		for i in choice.keys():
			var btn = panel.create_button(i)
			btn.pressed.connect(func(): panel.hide())
			btn.pressed.connect(load_text_block.bind(choice[i]))
	name_text.text = speaker
	words_text.text = words
	text_num+=1
	
	if text_data.has("Next"):
		var next_block = text_data["Next"]
		if !data.has(next_block):
			return
		talk_data = data[next_block]
		text_num = 0
	
func load_text_block(block_name :String)->void:
	if data == null:
		return
	if !data.has(block_name):
		return
	talk_data = data[block_name]
	text_num = 0
	load_text()

