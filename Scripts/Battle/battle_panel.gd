extends PanelManager
class_name BattlePanel

@export var action_point: Label
var action_text := "행동력 %d/%d"

enum Buttons {
	CENTER = 0,
	SKILL1,
	SKILL2,
	SKILL3,
	SKILL4,
	BAG,
	TALK,
	QUEST,
	RUN,
}

# 버튼 신호를 외부와 연결해주는 신호
signal skill_actived(index: Buttons)

# 현재 턴 캐릭터의 정보
var current_charcter: BattleCharacter

func _ready():
	var buttons = get_tree().get_nodes_in_group("battle_buttons")
	for i in buttons:
		i.disabled = true
		i.button_down.connect(_on_skill_buttons_down)

# 턴 변경되었음을 받는 함수
func _on_battle_scene_turn_character_changed(new_character: BattleCharacter):
	current_charcter = new_character
	if new_character.is_player == true:
		for i in get_tree().get_nodes_in_group("battle_buttons"):
			i.disabled = false
	else:
		for i in get_tree().get_nodes_in_group("battle_buttons"):
			i.disabled = true
			
	current_charcter.current_point = current_charcter.point
	action_point.text = action_text % [current_charcter.current_point, current_charcter.point]
	
func _process(delta):
	if current_charcter != null:
		action_point.text = action_text % [current_charcter.current_point, current_charcter.point]

# 스킬 버튼 눌렸을때 발동. 
func _on_skill_buttons_down(num):
	#print(num, " clicked")
	skill_actived.emit(num as Buttons)
	
# 현재 행동력보다 많은 행동력 소모하는 버튼 비활성화
func _check_skill_is_possible():
	pass
		
