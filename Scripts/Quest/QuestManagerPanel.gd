extends Control

#퀘스트 매니저 받아오기
var quest_manager :
	set(manager):
		quest_manager = manager as QuestManager

var select_quest : Quest
enum Mode{
	receive, process, clear
}
signal option_pressed
func set_panel(manager):
	quest_manager = manager
	if !quest_manager:
		return
	#왼쪽 패널 업데이트
	update_accept_panel()
	#오른쪽 패널 업데이트
	update_panel()

var curMode :Mode
func show_quest_detail(mode :Mode):
	curMode = mode
	#디테일 패널 활성화 및 설정
	$QuestDetail.show()
	$QuestDetail/Label.text = select_quest.title
	$QuestDetail/RichTextLabel.text = select_quest.description
	var option_btn = $QuestDetail/OptionBtn
	if mode == Mode.process:
		option_btn.hide()
	else:
		option_btn.show()
		

func option_press():
	if curMode == Mode.process:
		return
	elif curMode == Mode.clear:
		quest_manager.clear_quest(select_quest)
	elif curMode == Mode.receive:
		quest_manager.receive_quest(select_quest)
#왼쪽 패널에 수주 가능한 퀘스트 리스트 업데이트
func update_accept_panel():
	var parent = $QuestList/ScrollContainer/VBoxContainer
	quest_manager.import_quest()
	quest_manager.enqueue_quest()
	for i in parent.get_children():
		i.queue_free()
	#리스트에 해당하는 퀘스트 버튼 생성
	for i in quest_manager.quest_queue:
		var button = set_quest_button(i,parent)
		#퀘스트 수주 모드로 디테일 패널 열기
		button.pressed.connect(show_quest_detail.bind(Mode.receive))

#오른쪽 패널 현재 수주중인 퀘스트 리스트 업데이트
func update_panel():
	var parent = $QuestList2/ScrollContainer/VBoxContainer
	for i in parent.get_children():
		i.queue_free()
	#리스트에 해당하는 퀘스트 버튼 생성
	for i in PlayerData.quest_list:
		var button = set_quest_button(i,parent)
		#클리어 가능하면 옵션 버튼 활성화 아니면 비활성화
		if i.is_clearable(quest_manager.npc_name):
			button.pressed.connect(show_quest_detail.bind(Mode.clear))
		else:
			button.pressed.connect(show_quest_detail.bind(Mode.process))

#단일 버튼 생성 후 퀘스트와 바인딩
func set_quest_button(quest : Quest,parent):
	var button = Button.new()
	button.text = quest.title
	button.pressed.connect(func(): select_quest = quest)
	#button.pressed.connect(show_quest_detail.bind(mode))
	parent.add_child(button)
	return button

func close_panel():
	ViewManager.erase_panel(self)

func option_btn_pressed():
	option_pressed.emit(select_quest)
	option_pressed.emit()
	print("Option_pressed")
