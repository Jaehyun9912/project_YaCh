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
@onready var attribute_bar = $Interact/AttributeBar

# 캐릭터들의 정보를 담은 리스트
@onready var turn_char := get_tree().get_nodes_in_group("battle_characters").duplicate()
var player_character : BattleCharacter
var ally_character : Array[BattleCharacter]
var enemy_character : Array[BattleCharacter]

# 각 그룹의 수 
var enemy_count: 
	get: return len(enemy_character)
var ally_count: 
	get: return len(ally_character) + 1

# 현재 턴인 캐릭터의 정보
var now_character: BattleCharacter
var turn_cost:
	get:
		return now_character.current_point
	set(value):
		now_character.current_point = value

# 죽은 캐릭터 행동 이후 처리용 
var dead_player: Array[BattleCharacter]

# 맵의 JSON 데이터
var map_data : Dictionary

# 전투 종료 여부
var is_battle_end := false

# 맵 데이터 체크하는 변수들
@export var Check = ["enemys"]
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
	await panel.check_button_pressed
	
	timer.queue_free()

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
	
	for i in Check:
		if map_data.has(i) == false:
			printerr("No " + i)
			ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
			return
	
	# 속성 정보 세팅 
	attribute_bar.init(map_data.get("attribute", 100))
	total_point = map_data.get("point", 100)
	
	var idx = 0
	# 행동력 총합 및 캐릭터 정보 설정하기.
	for i in turn_char:
		if i.is_player == true:
			player_character = i
			# 플레이어 정보 및 태그 설정
			player_character.set_character(PlayerData.data, "Player.Character")
		else:
			enemy_character.append(i)
			# 적 정보 및 태그 설정
			var data = map_data["enemys"][idx]
			i.set_character(data, "Enemy." + data["tag"])
			idx += 1
			
		i.character_died.connect(_on_character_died)
		
	total_point_add = total_point * 0.2
	init_total_point = total_point

# 속도에 따른 행동력 계산 후 정렬에 반영 
func update_turn_point():
	total_speed = 0
	for i in turn_char:
		total_speed += i.speed
		
	for i in turn_char:
		i.point = i.speed / total_speed * total_point
	
	turn_char.sort_custom(func(a, b): return a.speed > b.speed)

# 전투를 관리하는 함수 (await 이용) 
func _battle():
	while true:
		# 한 루프가 돌면 행동력 업데이트 
		turn_count += 1
		update_turn_point()
		turn_cycle_start.emit()
		add_log.emit("%s 턴 시작" % turn_count)
		
		# Panel 쪽에서 turn end 발동 대기
		await turn_end
		
		for i in turn_char:
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
func remove_cost(skill):
	var cost = skill.get("cost", {})
	
	if cost is int or cost is float:
		turn_cost -= cost
		return

	for i in cost:
		if i == SkillManager.ACTION_POINT_ID:
			turn_cost -= cost.get(i, 0)
		else:
			attribute_bar.remove_value(i, cost[i])

	# turn_cost -= cost.get(SkillManager.ACTION_POINT_ID, 0)
	# if "element" in cost:
	# 	var element = cost.get("element", {})
	# 	for e in element:
	# 		attribute_bar.remove_value(e, element[e])

func set_effect(skill):
	var effect = skill.get("effect", {})
	for type in effect:
		if type == SkillManager.ACTION_POINT_ID:
			now_character.point += effect[type]
		else:
			attribute_bar.add_value(type, effect[type])
	

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
	var add_score = max(target.current_point * (counter.speed / total_speed) + counter_addition, total_point * 0.1)
	
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
	# 도망, 적 전부 처치 전투 종료 구현하기 
	is_battle_end = true
	
	# 모든 버튼 비활성화 
	ViewManager.bottom_panel.get_node("BattlePanel").end()
	var msg = $Interact/ResultPanel as ResultPanel
	
	match type:
		END_TYPE.RUN:
			msg.set_panel("전투에서 도망쳤다!")
			#msg.text = "전투에서 도망쳤다!"
		END_TYPE.WIN:
			#msg.text = "전투에서 승리했다!"
			
			var reward = ""
			# 보상 부여
			if map_data.has("rewards"):
				var rewards_data = map_data.rewards
				# 아이템 가져오기
				var items_to_reward = rewards_data.get("item", [])

				# 보상 아이템 설정하기
				for i in items_to_reward:
					
					# ID 체크 
					var item_id = i.get("id")
					if item_id == null:
						printerr("No Item ID in rewards!")
						continue

					var item = DataManager.get_item_artifact_data(item_id)
					# 개수 기본값 1
					var count = i.get("count", 1)

					# 보상 텍스트에 아이템 이름 추가하기
					reward += item.name
					if count > 1:
						reward += " " + str(count) + "개"
					reward += "\n"
					# 추가하기
					PlayerData.add_new_item(item_id, count)
			
			msg.set_panel("전투에서 승리했다!", "보상", reward)
		END_TYPE.LOSE:
			msg.set_panel("전투에서 패배했다...")

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
# 턴 종료 후 사망한 캐릭터 처리
	while dead_player.size() > 0:
		var dead = dead_player.pop_back()
		add_log.emit("%s 사망" % dead.name)
		
		if dead == player_character:
			print("player dead")
			battle_end(END_TYPE.LOSE)
			return true
		else:
			turn_char.erase(dead)
			dead.queue_free()
			enemy_character.erase(dead)
		
			if enemy_character.size() == 0:
				battle_end(END_TYPE.WIN)
				return true
	return false

# 캐릭터가 사망할시 일단 배열에 넣어놓고 나중에 처리
func _on_character_died(dead : BattleCharacter):
	print(dead.name, "is dead")
	dead_player.append(dead)

#endregion
