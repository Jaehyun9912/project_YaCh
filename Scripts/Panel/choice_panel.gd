extends Control

func _on_button_1_pressed():
	PlayerData.save_player()
	print("저장됨")
	
func _on_button_2_pressed():
	PlayerData.reset_player()
	print("리셋됨")
