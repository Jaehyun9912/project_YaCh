extends ColorRect

#@onready var manager = $"../.." as BattleManager
signal button_pressed(btn : BattlePanel.ButtonType)

@export var buttons: Array[Button]

# 버튼 비활성화 설정
func set_button_disabled(index, disabled: bool):
	if index is int and index >= 0 and index < len(buttons):
		buttons[index].disabled = disabled
	elif index is BattlePanel.ButtonType and index >= BattlePanel.ButtonType.INVENTORY and index <= BattlePanel.ButtonType.RUN:
		buttons[int(index) - int(BattlePanel.ButtonType.INVENTORY)].disabled = disabled

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
	# $TopButtonContainer/RunButton.disabled = new_character == null or not new_character.is_player
	set_button_disabled(BattlePanel.ButtonType.RUN, new_character == null or not new_character.is_player)
