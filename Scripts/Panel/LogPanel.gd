extends Control

# 텍스트 로그 넣는 컨테이너
var container:
	get:
		return $ColorRect/ScrollContainer/VBoxContainer

# json데이터
var data

# 대화 블록
var talk_data
# 블록 내 다음 인덱스
var text_num



func _ready():
	ViewManager.side_panel.set_text_panel()
	_load_data(ViewManager.cur_meta_data["Talk"])
	_load_text_block("Start")
	
	

# 데이터 불러오기
func _load_data(file_name : String) -> void:
	data = DataManager.get_data("Talk/" + file_name)
	text_num = 0
	

# 블록 내 인덱스 텍스트 설정하기
func _load_text() -> void:
	if talk_data.size() <= text_num:
		print("EOT")
		
		# 이거 오류 수정 필요할수도?
		_go_main_scene()
		return
	
	var text_data = talk_data[text_num]
	
	var speaker = text_data["Name"]
	var dialogue = text_data["Text"]
	
	# 선택지가 있을 때
	if text_data.has("Choice"):
		var choice = text_data["Choice"]
		var panel# = $Btns as BtnPanel
		panel = ViewManager.push_panel("BtnPanel",ViewManager.SCREEN.BOTTOM)
		
		for i in choice.keys():
			var btn = panel.create_button(i)
			btn.pressed.connect(func(): ViewManager.erase_panel(panel))
			btn.pressed.connect(_load_text_block.bind(choice[i]))
	
	ViewManager.side_panel.set_text(speaker,dialogue)
	_record_text(speaker,dialogue)
	# 다음 순서가 존재할 때
	if text_data.has("Next"):
		var next_block = text_data["Next"]
		if !data.has(next_block):
			return
		talk_data = data[next_block]
		text_num = 0
	else:
		text_num+=1


# 대화블록 설정하기
func _load_text_block(block_name :String)->void:
	if data == null:
		return
	if !data.has(block_name):
		return
	talk_data = data[block_name]
	text_num = 0
	_load_text()

# 로그 패널에 대화 추가하기
func _record_text(speaker,dialogue) -> void:
	var text = speaker + " : " + dialogue
	var text_box = RichTextLabel.new()
	text_box.fit_content = true
	text_box.text = text
	container.add_child(text_box)
	
	# 한 프레임 대기
	await get_tree().process_frame;
	
	# 스크롤 바 아래로 고정하기
	var scroll = container.get_parent() as ScrollContainer
	scroll.get_v_scroll_bar().value = scroll.get_v_scroll_bar().max_value
	

# 디버그용
func _go_main_scene():
	ViewManager.load_world("TestCountry","ChoicePanel")
