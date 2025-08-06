extends ColorRect

#@onready var manager = $"../.." as BattleManager
signal button_pressed(btn : BattlePanel.ButtonType)

func _on_bag_button_pressed():
	button_pressed.emit(BattlePanel.ButtonType.INVENTORY)

func _on_quest_button_pressed():
	button_pressed.emit(BattlePanel.ButtonType.QUEST)

func _on_log_button_pressed():
	button_pressed.emit(BattlePanel.ButtonType.LOG)

func _on_run_button_pressed():
	#manager.on_battle_panel_skill_actived(BattlePanel.ButtonType.RUN, null)
	button_pressed.emit(BattlePanel.ButtonType.RUN)

func on_battle_scene_turn_character_changed(new_character : BattleCharacter):
	$TopButtonContainer/RunButton.disabled = new_character == null or not new_character.is_player
