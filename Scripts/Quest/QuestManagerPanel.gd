extends Control

#퀘스트 매니저 받아오기
var quest_manager :
	set(manager):
		quest_manager = manager as QuestManager



func set_acceptable_panel():
	print("set_acceptable_panel")
	#퀘스트 리스트 패널 생성
	var panel = ViewManager.push_panel("QuestPanel")
	#수주 모드 설정
	panel.mode = panel.Mode.receive
	update_accept_panel(panel)
	#디테일 패널에 퀘스트 수주 연결 및 연결 후 퀘스트 패널 업데이트
	panel.option_pressed.connect(quest_manager.receive_quest)
	panel.option_pressed.connect(update_accept_panel.bind(panel))

func update_accept_panel(panel):
	#퀘스트 매니저 수주 가능 퀘스트 리스트 재정렬
	quest_manager.import_quest()
	quest_manager.enqueue_quest()
	panel.set_quest_buttons(quest_manager.quest_queue)

func set_clearable_panel():
	print("set_clearable_panel")
	#퀘스트 리스트 패널 생성
	var panel = ViewManager.push_panel("QuestPanel")
	#수주 모드 설정
	panel.mode = panel.Mode.clear
	update_clear_panel(panel)
	#디테일 패널에 퀘스트 클리어 연결 및 연결 후 퀘스트 패널 업데이트
	panel.option_pressed.connect(quest_manager.clear_quest)
	panel.option_pressed.connect(update_clear_panel.bind(panel))

func update_clear_panel(panel):
	#퀘스트 매니저 클리어 가능 퀘스트 리스트 재정렬
	var list : Array[Quest]
	for i in PlayerData.quest_list:
		if i.is_clearable(quest_manager.npc_name):
			list.append(i)
	panel.set_quest_buttons(list)

func close_panel():
	ViewManager.erase_panel(self)
