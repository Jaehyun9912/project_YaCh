extends Control


func _on_button_1_pressed():
	PlayerData.reset_player()
	PlayerData.save_player()
	print("Player Data Reset: ", SkillManager.player_skill)


#디버그용으로 잠시
func _on_button_2_pressed():
	var _panel = ViewManager.push_panel("InventoryPanel", ViewManager.SCREEN.FULL, {"mode": "full"})
	
	
func _on_button_3_pressed():
	PlayerData.add_new_item("bomb", 1)
	PlayerData.add_new_item("item:bomb", 2)
