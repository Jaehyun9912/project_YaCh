extends Control

#퀘스트 매니저 받아오기
var quest_manager :
	set(manager):
		quest_manager = manager as QuestManager
var panel:
	get:
		return $"QuestPanel"



func set_acceptable_panel():
	print("set_acceptable_panel")
	var new_panel = panel.duplicate()
	ViewManager.push_panel(new_panel)
	update_accept_panel(new_panel)
	new_panel.show()
	new_panel.option_pressed.connect(quest_manager.receive_quest)
	new_panel.option_pressed.connect(update_accept_panel.bind(new_panel))

func update_accept_panel(panel):
	quest_manager.import_quest()
	quest_manager.enqueue_quest()
	panel.set_quest_buttons(quest_manager.quest_queue)
	panel.mode = panel.Mode.receive

func set_clearable_panel():
	print("set_clearable_panel")
	var new_panel = panel.duplicate()
	ViewManager.push_panel(new_panel)
	new_panel.show()
	update_clear_panel(new_panel)
	new_panel.option_pressed.connect(quest_manager.clear_quest)
	new_panel.option_pressed.connect(update_clear_panel.bind(new_panel))

func update_clear_panel(panel):
	var list : Array[Quest]
	for i in PlayerData.quest_list:
		if i.is_clearable(quest_manager.npc_name):
			list.append(i)
	panel.set_quest_buttons(list)
	panel.mode = panel.Mode.clear

func close_panel():
	ViewManager.erase_panel(self)
