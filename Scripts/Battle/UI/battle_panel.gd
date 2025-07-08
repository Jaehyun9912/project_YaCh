extends Control
class_name BattlePanel

@onready var action_point = $ActionPoint as Label
@onready var buttons = get_tree().get_nodes_in_group("skill_buttons")
@onready var skill_button = $SkillButtonManager as SkillButtonManager
@onready var turn_point_bar = $TurnPointBar as TurnPointBar

var choicePanel

var manager: BattleManager

var action_text := "행동력 %d/%d"

enum Buttons {
	SKILL1,
	SKILL2,
	SKILL3,
	SKILL4,
	CENTER,
	INVENTORY,
	TALK,
	QUEST,
	RUN,
}

# 버튼 신호를 외부와 연결해주는 신호
signal skill_actived(index, target)

# 현재 턴 캐릭터의 정보
var current_charcter: BattleCharacter
var skill_target

# 현재 캐릭터의 행동력 저장 
var current_point

# 시작시
func _ready():
	manager = ViewManager.world_instance.get_node("BattleScene") as BattleManager
	skill_button.battle_panel = self
	
	# signal 연결
	manager.turn_character_changed.connect(_on_battle_scene_turn_character_changed)
	manager.turn_cycle_start.connect(_on_turn_cycle_start)
	manager.add_log.connect($BattleLog.add_log)
	skill_actived.connect(manager.on_battle_panel_skill_actived)
	
	# 버튼에 함수 설정, 플레이어 스킬 맞지 않으면 버튼 비활성화 
	for i in len(buttons) - 1:
		var btn = buttons[i]
		btn.disabled = true
		var skill = SkillManager.get_player_skill(i)
		if skill == null:
			btn.disabled = true
			btn.lock_disable = true
		
	turn_point_bar.set_information(manager.turn_char)
	manager.turn_end.emit()


# 턴 변경되었음을 받는 함수
func _on_battle_scene_turn_character_changed(new_character: BattleCharacter):
	# 현재 선택된 캐릭터 받아오기
	current_charcter = new_character
	
	# 포인트 설정하기 
	current_charcter.current_point = current_charcter.point
	action_point.text = action_text % [current_charcter.current_point, current_charcter.point]
	
	# 만약 플레이어라면 스킬 버튼 활성화 
	if new_character.is_player == true:
		skill_button.set_all_buttons(true)
		_check_skill_is_possible()
	else:
		skill_button.set_all_buttons(false)
	
# 무한 반복
func _process(_delta):
	# 행동력 표시 반영
	if current_charcter != null:
		if (current_charcter.current_point == current_point): return
		
		action_point.text = action_text % [current_charcter.current_point, current_charcter.point]
		turn_point_bar.update_point(current_charcter)
		current_point = current_charcter.current_point
	

# 현재 행동력보다 많은 행동력 소모하는 버튼 비활성화
func _check_skill_is_possible():
	for i in len(buttons):
		if i < Buttons.CENTER:
			buttons[i].disabled = not SkillManager.check_requirement(i, current_charcter.current_point, manager.attrubute_bar)
		else:
			return


func _on_skill_button_manager_skill_activated(skill, target):
	skill_actived.emit(skill, target)
	_check_skill_is_possible()

#region 특수 버튼
# 해당 버튼들은 특별한 기능을 가질 수 도 있기에 별도의 함수로 구현함
# 대화 버튼
func _on_button_talk_button_up():
	skill_actived.emit(Buttons.TALK, null)

# 퀘스트 버튼 
func _on_button_quest_button_up():
	skill_actived.emit(Buttons.QUEST, null)

# 도망가기 버튼
func _on_button_run_button_up():
	skill_actived.emit(Buttons.RUN, null)

# 인벤토리 버튼 
func _on_button_inventoy_button_up():
	var inven = PlayerData.inventory
	print(inven)
#endregion

#region getter
func get_all_enemy() -> Array[BattleCharacter]:
	return manager.enemy_character
	
func get_all_ally() -> Array[BattleCharacter]:
	return manager.ally_character
#endreigon

func end():
	skill_button.set_all_buttons(false)

# 대상 선택 때 대상이 변경될 경우 
func _on_skill_button_manager_target_changed(target, isally):
	var chars
	if isally:
		chars = get_all_ally()
	else:
		chars = get_all_enemy()
	
	for i in range(len(chars)):
		if i == target:
			chars[i].set_hp_outline_red()
		else:
			chars[i].set_hp_outline_default()
	
# 턴 사이클 한바퀴 시작
func _on_turn_cycle_start():
	turn_point_bar.set_point(manager.turn_char, manager.total_point)


