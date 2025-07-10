extends ColorRect

@onready var manager = $"../.." as BattleManager

func _on_bag_button_pressed():
	pass # Replace with function body.


func _on_quest_button_pressed():
	pass # Replace with function body.


func _on_log_button_pressed():
	manager.send_msg_to_panel.emit(BattlePanel.Order.OPEN_LOG_PANEL)


func _on_run_button_pressed():
	pass # Replace with function body.
