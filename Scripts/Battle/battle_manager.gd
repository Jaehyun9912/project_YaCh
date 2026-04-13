extends Node3D
class_name BattleManager

#region signal
# 턴 변경을 알리는 신호
signal turn_character_changed(new_character : BattleCharacter)

# 턴 행동을 완료했음을 알리는 신호
signal turn_end

# 스킬을 처리해줄 함수를 호출하는 신호 
signal use_skill(index, target, is_casting)
# 전투 사이클 시작을 알리는 신호
signal turn_cycle_start
# 로그 기록하는 신호
signal add_log(info: String)
# 어떤 스킬이든 (적 포함) 발동하면 알리는 신호
# 인자는 현재 필요 없어서 임시로 빼둠
signal skill_used
#endregion

#region Var
# 행동력 포인트
var total_point = 100
# 최초의 행동력 포인트
var init_total_point
# 매 턴 추가되는 행동력
var total_point_add

# 행동력 총합
var total_speed = 0
# 반격 시 기본으로 추가되는 행동력
var counter_addition = 10

# 지나간 턴 수
var turn_count := 0

# 가장 적은 포인트를 사용하는 행동 (자동 턴 넘기기 용)
var min_point_use = 1
# 매니저 
var battle_panel : BattlePanel
@onready var enemy_manager = $EnemyManager as EnemyManager
@onready var attribute_bar = $Interact/AttributeBar as AttributeBar
@onready var attribute_event_manager = $AttributeEventManager as AttributeEventManager
@onready var character_manager = $CharacterManager as CharacterManager

# 전체 적용되는 field_stat 저장용
# 예를 들어 각 원소는 id가 key, value는 그 속성의 배수임 (기본값 1) (예: {"fire": 0.8, "water": 1.2} )
var field_stat = {}

var player_character: BattleCharacter:
	get: return character_manager.player_character
var ally_character: Array[BattleCharacter]:
	get: return character_manager.ally_character
var enemy_character: Array[BattleCharacter]:
	get: return character_manager.enemy_character
var ally_count: int:
	get: return character_manager.ally_count
var enemy_count: int:
	get: return character_manager.enemy_count

# 현재 턴인 캐릭터의 정보
var now_character: BattleCharacter
var turn_cost:
	get:
		if now_character == null:
			return 0
		return now_character.current_point
	set(value):
		now_character.current_point = value

# 맵의 JSON 데이터
var map_data : Dictionary

# 전투 종료 여부
var is_battle_end := false

# 맵 데이터 체크하는 변수들
var _check = ["enemys"]
#endregion

#region other funcs
# 패널 쪽에서 설정 후 종료되면 전투 시작 
func _ready():

	var panel = $Interact/ResultPanel as ResultPanel
	var timer = Timer.new() as Timer
	add_child(timer)
	panel.set_panel("전투 개시!")
	
	timer.timeout.connect(panel._on_button_pressed)
	timer.start(1)

	for i in AttributeInformation.attribute.keys():
		field_stat[i] = 1.0

	await panel.check_button_pressed
	
	timer.queue_free()

	attribute_event_manager.init(attribute_bar, self)
	enemy_manager.init(self)

	# 캐릭터 매니저 초기화 및 관련 시그널 연결
	character_manager.character_died.connect(_on_character_died_check)
	character_manager.log_requested.connect(func(msg): add_log.emit(msg))
	
	_battle_set()
	_battle()

func add_attack_log(attacker, target, damage, before_hp):
	var info = "%s -> %s : 데미지 %s 부여\n%s 체력: %s -> %s" % [attacker, target, damage, target, before_hp, before_hp - damage]
	add_log.emit(info)
func add_turn_end_log():
	add_log.emit("%s : 턴 종료" % now_character.name)
#endregion
	
#region Main Battle
# 전투 전 설정
# 맵 정보 불러오기, 캐릭터 정보 할당하기, 행동력 구해주고 턴 순서에 맞추어 정렬하기
func _battle_set():
	# 맵 정보 불러오기
	var map_name = "World/" + ViewManager.cur_meta_data["World"]
	map_data = DataManager.get_data(map_name)
	
	# 필수 정보 확인하기 
	if map_data.size() == 0:
		printerr("No MapData!")
		ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
	
	for i in _check:
		if map_data.has(i) == false:
			printerr("No " + i)
			ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
			return
	
	# 속성 정보 세팅 
	attribute_bar.init(map_data.get("attribute", 100))
	total_point = map_data.get("point", 100)
	total_point_add = total_point * 0.2
	init_total_point = total_point

	# 캐릭터 매니저에게 캐릭터 설정 위임
	character_manager.init(get_tree().get_nodes_in_group("battle_characters"), map_data, total_point)


# 전투를 관리하는 함수 (await 이용) 
func _battle():
	while true:
		# 한 루프가 돌면 행동력 업데이트 
		turn_count += 1
		character_manager.update_turn_point(total_point)
		turn_cycle_start.emit()
		add_log.emit("%s 턴 시작" % turn_count)
		
		# Panel 쪽에서 turn end 발동 대기
		await turn_end
		
		for i in character_manager.turn_char:
			change_now_char(i, i.point)
			
			# 플레이어 턴 
			if i.is_player == true:
				print("player turn")
			# 적 턴 
			else:
				print("enemy turn")	
				
			# 턴 행동 종료 대기 
			await turn_end
			add_turn_end_log()
			ViewManager.side_panel.set_hp_panel()
			turn_character_changed.emit(null)
			if check_dead_char():
				return
			if is_battle_end:
				return
						
			print("turn end")
		# 한 루프 끝나면 턴포인트 증가 
		if total_point < init_total_point * 2:
			total_point += total_point_add

# 턴 진행하는 캐릭터 변경
func change_now_char(new_char : BattleCharacter, point):
	now_character = new_char
	turn_cost = point
	turn_character_changed.emit(new_char)

#endregion

#region Skill func
# 코스트 제거하기 
func remove_cost(skill: SkillData):
	var cost = skill.requirements.cost
	
	for i in cost:
		if i == SkillManager.ACTION_POINT_ID:
			turn_cost -= cost.get(i, 0)
		else:
			attribute_bar.remove_value(i, cost[i])

func set_attribute_change(element_changes: Dictionary):
	for type in element_changes:
		if type == SkillManager.ACTION_POINT_ID:
			now_character.point += element_changes[type]
		else:
			attribute_bar.add_value(type, element_changes[type])
	

# 버튼 눌렀을때
func on_battle_panel_skill_actived(index, target, is_casting):
	
	if index is Dictionary:
		use_skill.emit(index, target, is_casting)
	else:
		match index:
			# 버튼에 해당하는 효과 발동 
			BattlePanel.ButtonType.CENTER:
				turn_end.emit()
			BattlePanel.ButtonType.SKILL1:
				use_skill.emit(0, target, is_casting)
			BattlePanel.ButtonType.SKILL2:
				use_skill.emit(1, target, is_casting)
			BattlePanel.ButtonType.SKILL3:
				use_skill.emit(2, target, is_casting)
			BattlePanel.ButtonType.SKILL4:
				use_skill.emit(3, target, is_casting)
			BattlePanel.ButtonType.RUN:
				battle_end(END_TYPE.RUN)
			_:
				pass
	
	if now_character.current_point < min_point_use:
		turn_end.emit()
			
	check_dead_char()
	
# 카운터 발동 함수
func apply_counter(target, counter):
	# 남은 턴 * (내 속도 / 모든 속도 합) + 보정치 > 필드전체행동력비례 최솟값
	var add_score = max(target.current_point * (counter.speed / character_manager.total_speed) + counter_addition, total_point * 0.1)
	
	#enemy_manager.status = EnemyManager.AttackStatus.End
	change_now_char(counter, add_score)
	battle_panel.turn_point_bar.set_outline(counter, true)
	
	print("반격! 가져온 행동력: ", add_score)
	print(counter.current_point)
	
func set_casting_panel(title, time, button_type, callback):
	battle_panel.set_casting_panel(title, time, button_type, callback)
#endregion
	
#region END
enum END_TYPE {
	RUN,
	WIN,
	LOSE
}

# 들어온 타입에 따라 전투 종료 
func battle_end(type: END_TYPE):
	is_battle_end = true
	
	# 모든 버튼 비활성화 
	ViewManager.bottom_panel.get_node("BattlePanel").end()
	var result_panel = $Interact/ResultPanel as ResultPanel
	
	match type:
		END_TYPE.RUN:
			result_panel.process_run()
			
		END_TYPE.WIN:
			result_panel.process_win(map_data)

		END_TYPE.LOSE:
			result_panel.process_lose()

func _on_end_button_pressed():
	if is_battle_end:
		ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
		ViewManager.side_panel.set_hide_panel()
	else:
		$Interact/ResultPanel.close_panel()
#endregion

#region 죽은 캐릭터
# 죽은 캐릭터 처리하는 함수
func check_dead_char():
	return character_manager.check_dead_char()

# CharacterManager에서 사망 신호를 받으면 처리
func _on_character_died_check(_dead: BattleCharacter, is_player: bool, is_all_enemies_dead: bool):
	if is_player:
		battle_end(END_TYPE.LOSE)
	elif is_all_enemies_dead:
		battle_end(END_TYPE.WIN)
#endregion
