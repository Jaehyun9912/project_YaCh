extends Control
class_name BattlePanel

@onready var action_point = $TurnPointBar/ActionPoint as Label
@onready var turn_point_bar = $TurnPointBar as TurnPointBar
@onready var top_button = $TopButton

var skill_buttons
var choicePanel

var manager: BattleManager
var skill_button: SkillButtonManager

var action_text := "행동력 %d/%d"

enum ButtonType {
	SKILL1,
	SKILL2,
	SKILL3,
	SKILL4,
	CENTER,
	INVENTORY,
	LOG,
	QUEST,
	RUN,
}

# 버튼 신호를 외부와 연결해주는 신호
signal skill_actived(index : BattlePanel.ButtonType, target)

# 현재 턴 캐릭터의 정보
var current_charcter: BattleCharacter
var skill_target

# 현재 캐릭터의 행동력 저장 
var current_point

# 시작시
func _ready():
	manager = ViewManager.world_instance.get_node("BattleScene") as BattleManager
	skill_button = $SkillButtonManager as SkillButtonManager
	skill_button.battle_panel = self
	
	# signal 연결
	manager.turn_character_changed.connect(_on_battle_scene_turn_character_changed)
	manager.turn_cycle_start.connect(_on_turn_cycle_start)
	manager.add_log.connect($BattleLog.add_log)
	manager.battle_panel = self
	skill_actived.connect(manager.on_battle_panel_skill_actived)
	
	skill_buttons = skill_button.buttons
	
	# 버튼에 함수 설정, 플레이어 스킬 맞지 않으면 버튼 비활성화 
	for i in len(skill_buttons) - 1:
		var btn = skill_buttons[i]
		btn.disabled = true
		var skill = SkillManager.get_player_skill(i)
		if skill == null:
			btn.lock_disable = true
	#manager.turn_end.emit()
	$CastingPanel.battle_panel = self

# 턴 변경되었음을 받는 함수
func _on_battle_scene_turn_character_changed(new_character: BattleCharacter):
	top_button.on_battle_scene_turn_character_changed(new_character)
	
	# 현재 선택된 캐릭터 받아오기
	current_charcter = new_character
	
	if new_character == null:
		skill_button.set_all_buttons(false)
		return
	
	# 포인트 설정하기 
	# current_charcter.current_point = current_charcter.point
	action_point.text = action_text % [current_charcter.current_point, current_charcter.point]
	
	turn_point_bar.set_outline(current_charcter, false)
	
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

# 조건을 만족하는 스킬만 활성화
func _check_skill_is_possible():
	if current_charcter == null or not current_charcter.is_player:
		return
	
	for i in len(skill_buttons):
		if i < ButtonType.CENTER:
			skill_buttons[i].disabled = not SkillManager.check_requirement(SkillManager.get_player_skill(i), current_charcter.current_point, manager.attribute_bar)
		else:
			return

# 스킬 발동을 받아서 전달
func _on_skill_button_manager_skill_activated(skill : BattlePanel.ButtonType, target):
	skill_actived.emit(skill, target)
	_check_skill_is_possible()

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
	skill_button.set_all_buttons(false)
	if manager.turn_count == 1:
		turn_point_bar.set_information(manager.turn_char)
		turn_point_bar.first_appear_anim()
	else:
		turn_point_bar.set_point(manager.turn_char, manager.total_point)
	
	await turn_point_bar.end_set_point
	manager.turn_end.emit()

# 패널 상단의 버튼 4개 처리
func _on_top_button_button_pressed(btn : BattlePanel.ButtonType):
	match btn:
		ButtonType.LOG:
			$BattleLog.enable_panel()
			
func set_casting_panel(text, time, is_button_visible, callback):
	$CastingPanel.set_casting_panel(text, time, is_button_visible, callback)
