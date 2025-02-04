extends Control

var container:
	get:
		return $"QuestList/ScrollContainer/VBoxContainer"



var select_quest : Quest
#퀘스트 상세내용 및 옵션 제공
func show_quest_detail():
	#디테일 패널 활성화 및 설정
	$"ColorRect2".show()
	$"ColorRect2/Label".text = select_quest.title
	$"ColorRect2/RichTextLabel".text = select_quest.description

#버튼 1개와 퀘스트 연결
func set_quest_button(quest : Quest):
	var button = Button.new()
	button.text = quest.title
	button.pressed.connect(func(): select_quest = quest)
	button.pressed.connect(show_quest_detail)
	container.add_child(button)

func set_quest_buttons(list : Array[Quest]):
	for i in container.get_children():
		i.queue_free()
	#리스트에 해당하는 퀘스트 버튼 생성
	for i in list:
		set_quest_button(i)

#패널 제거하기
func close_panel():
	ViewManager.erase_panel(self)

