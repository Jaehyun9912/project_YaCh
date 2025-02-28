extends Control

var container:
	get:
		return $"QuestList/ScrollContainer/VBoxContainer"




# 퀘스트 디테일 패널 표시
func show_quest_detail(quest):
	var detail_panel = ViewManager.push_panel("QuestDetailPanel")
	detail_panel.any_button_pressed.connect(ViewManager.erase_panel.bind(detail_panel))
	detail_panel.set_quest(quest,1)


# 퀘스트 리스트에 대한 버튼들 생성
func set_quest_buttons(list : Array[Quest]):
	# 생성되어있던 버튼 제거
	for i in container.get_children():
		i.queue_free()
	# 새 버튼 생성
	for i in list:
		_set_quest_button(i)


# 패널 닫기
func close_panel():
	ViewManager.erase_panel(self)


# 퀘스트와 버튼 연결, 시그널 추가
func _set_quest_button(quest : Quest):
	var button = Button.new()
	button.text = quest.title
	button.pressed.connect(show_quest_detail.bind(quest))
	container.add_child(button)

