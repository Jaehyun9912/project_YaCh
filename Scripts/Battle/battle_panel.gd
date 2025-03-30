extends Control
class_name BattlePanel

@onready var action_point = $ActionPoint as Label
@onready var buttons = get_tree().get_nodes_in_group("skill_buttons")
@onready var skill_button = $SkillButtonManager as SkillButtonManager

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
signal skill_actived(index: Buttons, target)

# 현재 턴 캐릭터의 정보
var current_charcter: BattleCharacter
var skill_target

# 시작시
func _ready():
	manager = ViewManager.world_instance.get_node("BattleScene") as BattleManager
	skill_button.battle_panel = self
	
	manager.turn_character_changed.connect(_on_battle_scene_turn_character_changed)
	skill_actived.connect(manager.on_battle_panel_skill_actived)
	
	# 버튼에 함수 설정, 플레이어 스킬 맞지 않으면 버튼 비활성화 
	for i in len(buttons):
		var btn = buttons[i]
		btn.disabled = true
		var skill = SkillManager.get_player_skill(i)
		if skill == null:
			btn.disabled = true
			btn.lock_disable = true
		
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
		
	# 디버그용
	print("디버그용 스킬 버튼 활성화 작동")
	skill_button.set_all_buttons(true)
	
# 무한 반복
func _process(_delta):
	# 행동력 표시 반영
	if current_charcter != null:
		action_point.text = action_text % [current_charcter.current_point, current_charcter.point]

# 현재 행동력보다 많은 행동력 소모하는 버튼 비활성화
func _check_skill_is_possible():
	for i in len(buttons):
		if i < Buttons.CENTER:
			buttons[i].disabled = not SkillManager.check_requirement(i, current_charcter.current_point, manager.attrubute_bar)

# 스킬 버튼 눌렸을때 발동. 
func _on_skill_buttons_down(num):
	print("button pressed ", num)
	
	# 센터면 바로 종료 
	if num == Buttons.CENTER:
		skill_actived.emit(Buttons.CENTER, null)
		return
	
	# 사이드 패널에 정보 띄우기 
	var skill = SkillManager.get_player_skill(num-1)
	SidePanel.set_info_panel(skill.get("name", ""), skill.get("description", ""))
			
	
	# 스킬 대상 정하기 
	skill_target = manager.skill_manager.get_target(num-1)
	
	if skill_target is String and skill_target == "self":
		choicePanel.set_self_panel()
	else:
		var target_count = skill_target.get("count", 0)
		var team = skill_target.get("team", false)
		# 0이하 : 전부 대상 
		if target_count < 1:
			choicePanel.set_all_panel(team)
		
		# 타겟 유형에 따라 적/아군 개수 가져오기 
		var cnt := 0
		if skill_target["team"]:
			cnt = manager.ally_count
		else:
			cnt = manager.enemy_count
		
		# 한명만 남아서 선택 할 필요 없음
		if cnt == 1:
			choicePanel.set_all_panel(team)
		# 아니면 선택 시작 
		else:
			choicePanel.set_choice_panel(cnt, target_count, team)
			
	# 결과 받아오기 
	var end = await choicePanel.choice_end
	SidePanel.mode = SidePanel.Mode.HP
	
	# 취소 시 null 이 반환됨 
	if end == null:
		return

	skill_actived.emit(num, end)
	_check_skill_is_possible()
	
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

func get_all_enemy():
	return manager.enemy_character
	
func get_all_ally():
	return manager.ally_character
