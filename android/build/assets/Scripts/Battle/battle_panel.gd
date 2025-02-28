extends Control
class_name BattlePanel

@onready var action_point = $ActionPoint as Label
@onready var buttons = get_tree().get_nodes_in_group("battle_buttons")
@onready var choicePanel = $CharacterChoicePanel as CharacterChoicePanel

var manager: BattleManager

var action_text := "행동력 %d/%d"

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
signal skill_actived(index: Buttons, target)

# 현재 턴 캐릭터의 정보
var current_charcter: BattleCharacter
var skill_target

# 시작시
func _ready():
	manager = ViewManager.world_instance.get_node("BattleScene") as BattleManager
	
	manager.turn_character_changed.connect(_on_battle_scene_turn_character_changed)
	skill_actived.connect(manager.on_battle_panel_skill_actived)
	
	# 버튼에 함수 설정, 플레이어 스킬 맞지 않으면 버튼 비활성화 
	for i in buttons:
		i.disabled = true
		if i is RoundButton:
			i.button_down.connect(_on_skill_buttons_down)
			if i.button_number != Buttons.CENTER:
				var skill = manager.skill_manager.get_player_skill(i.button_number-1)
				if skill == null:
					i.disabled = true
					i.lock_disable = true
					continue
		
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
func _process(_delta):
	# 행동력 표시 반영
	if current_charcter != null:
		action_point.text = action_text % [current_charcter.current_point, current_charcter.point]

# 현재 행동력보다 많은 행동력 소모하는 버튼 비활성화
func _check_skill_is_possible():
	for i in buttons:
		if i is RoundButton and i.button_number != Buttons.CENTER:
			i.disabled = not manager.skill_manager.check_requirement(i.button_number-1, current_charcter.current_point)
			
# 모든 버튼 설정하기 (true : 활성화, false : 비활성화)
func set_all_button(OnOff : bool) -> void:
	for i in get_tree().get_nodes_in_group("battle_buttons"):
		i.disabled = !OnOff

# 스킬 버튼 눌렸을때 발동. 
func _on_skill_buttons_down(num):
	print("button pressed ", num)
	
	if num == Buttons.CENTER:
		skill_actived.emit(Buttons.CENTER, null)
	
	# 스킬 대상 정하기 
	skill_target = manager.skill_manager.get_target(num-1)
	
	if skill_target is String and skill_target == "self":
		choicePanel.set_self_panel()
	else:
		var target_count = skill_target.get("count", 0)
		# 0이하 : 전부 대상 
		if target_count < 1:
			choicePanel.set_all_panel()
		
		# 타겟 유형에 따라 적/아군 개수 가져오기 
		var cnt := 0
		if skill_target["team"]:
			cnt = manager.ally_count
		else:
			cnt = manager.enemy_count
		
		# 한명만 남아서 선택 할 필요 없음
		if cnt == 1:
			choicePanel.set_all_panel()
		# 아니면 선택 시작 
		else:
			choicePanel.set_choice_panel(cnt, target_count)
			
	# 결과 받아오기 
	var end = await choicePanel.choice_end
	# 취소 시 null 이 반환됨 
	if end == null:
		return

	skill_actived.emit(num, end)
	_check_skill_is_possible()
	
func _callback_choice(clicked_index):
	pass
	
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
