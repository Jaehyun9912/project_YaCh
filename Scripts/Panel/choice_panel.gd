extends Control

func _on_button_1_pressed():
	PlayerData.skill[0] = "base_attack"
	PlayerData.skill[1] = "base_fire"
	PlayerData.skill[2] = "base_water"
	PlayerData.skill[3] = "base_dirt"
	PlayerData.save_player()
	print("변경 후 저장됨 ")
	
func _on_button_2_pressed():
	PlayerData.reset_player()
	print("리셋됨")

func _on_button_3_pressed():
	PlayerData.load_player()
	print("로드됨") 
