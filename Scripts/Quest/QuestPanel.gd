extends Control

var container:
	get:
		return $"QuestList/VBoxContainer"

#패널 디테일 모드
enum Mode{process,receive,clear}
var mode = Mode.process

#옵션 버튼 클릭
signal option_pressed
var select_quest : Quest
#퀘스트 상세내용 및 옵션 제공
func show_quest_detail():
	#디테일 패널 활성화 및 설정
	$"ColorRect2".show()
	$"ColorRect2/Label".text = select_quest.title
	$"ColorRect2/RichTextLabel".text = select_quest.description
	print(mode)
	print(select_quest.id)
	#모드에 따른 설정 구분
	if mode == Mode.receive:
		#옵션 버튼 => 수주버튼으로 변경
		$"ColorRect2/OptionBtn".show()
		$"ColorRect2/OptionBtn".text = "퀘스트 수주"
	elif mode == Mode.clear:
		#옵션 버튼 => 제출버튼으로 변경
		$"ColorRect2/OptionBtn".show()
		$"ColorRect2/OptionBtn".text = "퀘스트 제출"

#현재 선택중인 퀘스트 설정
func set_select_quest(quest : Quest):
	select_quest = quest as Quest


#버튼 1개와 퀘스트 연결
func set_quest_button(quest : Quest):
	var button = Button.new()
	button.text = quest.title
	button.pressed.connect(set_select_quest.bind(quest))
	button.pressed.connect(show_quest_detail)
	container.add_child(button)

func set_quest_buttons(list : Array[Quest]):
	print(mode)
	#모드별 패널 텍스트 설정
	if mode == Mode.process:
		$QuestList/Label.text = "수주중인 퀘스트"
	elif mode == Mode.clear:
		$QuestList/Label.text = "제출 가능 퀘스트"
	else:
		$QuestList/Label.text = "수주 가능 퀘스트"
	#패널에 있던 퀘스트 버튼 제거
	for i in container.get_children():
		i.queue_free()
	#리스트에 해당하는 퀘스트 버튼 생성
	for i in list:
		set_quest_button(i)

#패널 제거하기
func close_panel():
	ViewManager.erase_panel(self)

#옵션 버튼 클릭시 옵션 시그널 활성화
func option_button():
	option_pressed.emit(select_quest)
	option_pressed.emit()
	print("Option_pressed")
