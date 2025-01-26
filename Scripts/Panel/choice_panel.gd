extends Control

func _on_button_1_pressed():
	var skills = PlayerData.skills
	skills[0] = "base_attack"
	skills[1] = "base_fire"
	skills[2] = "base_water"
	skills[3] = "base_dirt"
	PlayerData.skills = skills
	PlayerData.save_player()
	print("변경 후 저장됨 ")
	
#디버그용으로 잠시
func _on_button_2_pressed():
	#PlayerData.reset_player()
	#print("리셋됨")
	var panel = ViewManager.push_panel("QuestPanel")
	panel.set_quest_buttons(PlayerData.quest_list)
	PlayerData.quest_updated.connect(panel.set_quest_buttons)
	panel.mode = panel.Mode.process
	print("수주중인 퀘스트 보기")
	
	

func _on_button_3_pressed():
	PlayerData.add_new_item("bomb", 1)
	PlayerData.add_new_item("item:bomb", 2)
	PlayerData.add_new_item("artifact:pandora_cube", 1)
