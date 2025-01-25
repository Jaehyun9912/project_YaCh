extends Control

#퀘스트 매니저 받아오기
var quest_manager :
	set(manager):
		quest_manager = manager as QuestManager



func set_acceptable_panel():
	print("set_acceptable_panel")
	var panel = ViewManager.push_panel("QuestPanel")
	update_accept_panel(panel)
	panel.option_pressed.connect(quest_manager.receive_quest)
	panel.option_pressed.connect(update_accept_panel.bind(panel))

func update_accept_panel(panel):
	quest_manager.import_quest()
	quest_manager.enqueue_quest()
	panel.mode = panel.Mode.receive
	panel.set_quest_buttons(quest_manager.quest_queue)

func set_clearable_panel():
	print("set_clearable_panel")
	var panel = ViewManager.push_panel("QuestPanel")
	update_clear_panel(panel)
	panel.option_pressed.connect(quest_manager.clear_quest)
	panel.option_pressed.connect(update_clear_panel.bind(panel))

func update_clear_panel(panel):
	var list : Array[Quest]
	for i in PlayerData.quest_list:
		if i.is_clearable(quest_manager.npc_name):
			list.append(i)
	panel.mode = panel.Mode.clear
	panel.set_quest_buttons(list)

func close_panel():
	ViewManager.erase_panel(self)
