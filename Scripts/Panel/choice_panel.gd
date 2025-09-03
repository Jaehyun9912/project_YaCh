extends Control



func _on_button_1_pressed():
	PlayerData.reset_player()
	PlayerData.save_player()
	print("Player Data Reset: ", PlayerData.skills)


#디버그용으로 잠시
func _on_button_2_pressed():
	var panel = ViewManager.push_panel("QuestPanel",ViewManager.SCREEN.BOTTOM)
	panel.set_quest_buttons(PlayerData.quest_list)
	print("수주중인 퀘스트 보기")
	
	

func _on_button_3_pressed():
	PlayerData.add_new_item("bomb", 1)
	PlayerData.add_new_item("item:bomb", 2)
	
