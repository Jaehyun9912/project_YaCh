extends Control

func _on_button_1_pressed():
	var skills = PlayerData.skills
	skills[0] = "base_attack"
	skills[1] = "base_fire"
	skills[2] = "base_water"
	skills[3] = "base_dirt"
	PlayerData.skills = skills
	PlayerData.save_player()
	print(skills)
	
func _on_button_2_pressed():
	PlayerData.reset_player()
	print("리셋됨")

func _on_button_3_pressed():
	PlayerData.add_new_item("bomb", 1)
	PlayerData.add_new_item("item:bomb", 2)
	PlayerData.add_new_item("artifact:pandora_cube", 1)
