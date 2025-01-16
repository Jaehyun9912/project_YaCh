extends Control
class_name BattlePanel

@onready var action_point = $ActionPoint as Label
var manager: BattleManager
var action_text := "행동력 %d/%d"

var action_points_list := [0, 0, 0, 0]

enum Buttons {
	CENTER = 0,
	SKILL1,
	SKILL2,
	SKILL3,
	SKILL4,
	INVENTORY,
	TALK,
	QUEST,
	RUN,
}

# 버튼 신호를 외부와 연결해주는 신호
signal skill_actived(index: Buttons)

# 현재 턴 캐릭터의 정보
var current_charcter: BattleCharacter

# 시작시
func _ready():
	manager = ViewManager.world_instance.get_node("BattleScene") as BattleManager
	
	manager.turn_character_changed.connect(_on_battle_scene_turn_character_changed)
	skill_actived.connect(manager.on_battle_panel_skill_actived)
	
	var skill_info = DataManager.get_data("skill_info")
	
	var buttons = get_tree().get_nodes_in_group("battle_buttons")
	for i in buttons:
		i.disabled = true
		if i is RoundButton:
			i.button_down.connect(_on_skill_buttons_down)
			
			if i.button_number != Buttons.CENTER:
				var index = i.button_number-1
				var skill = PlayerData.skills[index]
				if skill_info.has(skill) == false:
					i.disabled = true
					i.lock_disable = true
					action_points_list[index] = [0, null]
					continue
				
				action_points_list[index] = [skill_info[skill]["cost"], i]
		
	manager.turn_end.emit()

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
	
	
# 무한 반복
func _process(delta):
	# 행동력 표시 반영
	if current_charcter != null:
		action_point.text = action_text % [current_charcter.current_point, current_charcter.point]

# 현재 행동력보다 많은 행동력 소모하는 버튼 비활성화
func _check_skill_is_possible():
	var point = current_charcter.current_point
	for i in action_points_list:
		if point < i[0]:
			i[1].disabled = true
	
# 모든 버튼 설정하기 (true : 활성화, false : 비활성화)
func set_all_button(OnOff : bool) -> void:
	for i in get_tree().get_nodes_in_group("battle_buttons"):
		i.disabled = !OnOff

# 스킬 버튼 눌렸을때 발동. 
func _on_skill_buttons_down(num):
	#print(num, " clicked")
	skill_actived.emit(num)
	_check_skill_is_possible()
	
# 해당 버튼들은 특별한 기능을 가질 수 도 있기에 별도의 함수로 구현함
# 대화 버튼
func _on_button_talk_button_up():
	skill_actived.emit(Buttons.TALK)

# 퀘스트 버튼 
func _on_button_quest_button_up():
	skill_actived.emit(Buttons.QUEST)

# 도망가기 버튼
func _on_button_run_button_up():
	skill_actived.emit(Buttons.RUN)

# 인벤토리 버튼 
func _on_button_inventoy_button_up():
	var inven = PlayerData.inventory
	print(inven)
