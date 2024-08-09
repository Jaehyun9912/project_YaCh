extends PanelManager
class_name BattlePanel

@export var action_point: Label
var action_text := "행동력 %d/%d"

# 스킬 버튼 리스
var skill_buttons: Array[Button]
var current_charcter: BattleCharacter

func _ready():
	var buttons = get_tree().get_nodes_in_group("battle_buttons")
	for i in buttons:
		i.disabled = true


func _on_battle_scene_turn_character_changed(new_character: BattleCharacter):
	current_charcter = new_character
	if new_character.is_player == true:
		for i in get_tree().get_nodes_in_group("battle_buttons"):
			i.disabled = false
			
	current_charcter.current_point = current_charcter.point
	action_point.text = action_text % [current_charcter.current_point, current_charcter.point]
	


func _on_center_button_button_down():
	print("center clicked")
