extends Node3D
class_name BattleManager

# 턴 변경을 알리는 신호
signal turn_character_changed(new_character : BattleCharacter)

# 턴 행동을 완료했음을 알리는 신호
signal turn_end

# 스킬을 처리해줄 함수를 호출하는 신호 
signal use_skill(index, target)
# 전투 사이클 시작을 알리는 신호
signal turn_cycle_start

# 행동력 포인트
var total_point = 100
var init_total_point
var total_point_add

# 가장 적은 포인트를 사용하는 행동 (자동 턴 넘기기 용)
var min_point_use = 1
# 매니저 
@onready var enemy_manager = $EnemyManager as EnemyManager
@onready var attrubute_bar = $Interact/AttributeBar

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

var map_data : Dictionary

# 패널 쪽에서 설정 후 종료되면 전투 시작 
func _ready():
	await turn_end
	
	_battle()
	
# 전투 전 설정
# 맵 정보 불러오기, 캐릭터 정보 할당하기, 행동력 구해주고 턴 순서에 맞추어 정렬하기
func _battle_set():
	# 맵 정보 불러오기
	var map_name = "World/" + ViewManager.now_map_name
	map_data = DataManager.get_data(map_name)
	
	# 필수 정보 확인하기 
	if map_data.size() == 0:
		printerr("No MapData!")
		ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
	const CHECK = ["enemys"]
	for i in CHECK:
		if map_data.has(i) == false:
			printerr("No " + i)
			ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
			return
	
	# 속성 정보 세팅 
	attrubute_bar.init(map_data.get("attribute", 100))
	total_point = map_data.get("point", 100)
	
	var idx = 0
	# 행동력 총합 및 캐릭터 정보 설정하기.
	for i in turn_char:
		if i.is_player == true:
			player_character = i
			player_character.set_character(PlayerData.data, "Player.Character")
		else:
			enemy_character.append(i)
			var data = map_data["enemys"][idx]
			i.set_character(data, "Enemy." + data["tag"])
			idx += 1
			
		i.character_died.connect(_on_character_died)
	total_point_add = total_point * 0.2
	init_total_point = total_point

# 속도에 따른 행동력 계산 후 정렬에 반영 
func update_turn_point():
	var total_speed = 0
	for i in turn_char:
		total_speed += i.speed
		
	for i in turn_char:
		i.point = i.speed / total_speed * total_point
	
	turn_char.sort_custom(func(a, b): return a.speed > b.speed)

# 전투를 관리하는 함수 (await 이용) 
func _battle():
	_battle_set()
	
	while true:
		# 한 루프가 돌면 행동력 업데이트 
		update_turn_point()
		turn_cycle_start.emit()
		for i in turn_char:
			now_character = i
			turn_character_changed.emit(i)
			
			# 플레이어 턴 
			if i.is_player == true:
				print("player turn")
			# 적 턴 
			else:
				print("enemy turn")	
				
			# 턴 행동 종료 대기 
			await turn_end
			_check_dead_char()
						
			print("turn end")
		# 한 루프 끝나면 턴포인트 증가 
		if total_point < init_total_point * 2:
			total_point += total_point_add

# 코스트 제거하기 
func remove_cost(skill):
	var cost = skill.get("cost", {})
	
	if not cost is Dictionary:
		turn_cost -= cost
		return
		
	turn_cost -= cost.get("point", 0)
	if "element" in cost:
		var element = cost.get("element", {})
		for e in element:
			attrubute_bar.remove_value(e, element[e])

# 버튼 눌렀을때
func on_battle_panel_skill_actived(index : BattlePanel.Buttons, target):
	#var cost := 0
	#print("target : ", target)
	match index:
		# 버튼에 해당하는 효과 발동 
		BattlePanel.Buttons.CENTER:
			turn_end.emit()
		BattlePanel.Buttons.SKILL1:
			use_skill.emit(0, target)
		BattlePanel.Buttons.SKILL2:
			use_skill.emit(1, target)
		BattlePanel.Buttons.SKILL3:
			use_skill.emit(2, target)
		BattlePanel.Buttons.SKILL4:
			use_skill.emit(3, target)
		BattlePanel.Buttons.RUN:
			_battle_end(END_TYPE.RUN)
	
	if now_character.current_point < min_point_use:
		turn_end.emit()
			
	_check_dead_char()
	
#region END
enum END_TYPE {
	RUN,
	WIN,
	LOSE
}

# 들어온 타입에 따라 전투 종료 
func _battle_end(type: END_TYPE):
	# 도망, 적 전부 처치 전투 종료 구현하기 
	
	# 모든 버튼 비활성화 
	ViewManager.current_panel.get_node("BattlePanel").end()
	var msg = $Interact/ResultPanel as ResultPanel
	
	match type:
		END_TYPE.RUN:
			msg.set_panel("전투에서 도망쳤다!")
			#msg.text = "전투에서 도망쳤다!"
		END_TYPE.WIN:
			#msg.text = "전투에서 승리했다!"
			
			var reward = ""
			# 보상 부여
			if map_data.has("rewards") and map_data["rewards"].has("item"):
				for i in map_data["rewards"]["item"]:
					if (i.has("id") == false):
						printerr("No Item ID in rewards!")
						continue
						
					var item = DataManager.get_item_artifact_data(i.id)
					if (i.has("count") == false):
						reward += item.name + "\n"
						PlayerData.add_new_item(i.id, 1)
					else:
						reward += item.name + " " + str(i.count) + "개\n"
						PlayerData.add_new_item(i.id, i.count)
						
			msg.set_panel("전투에서 승리했다!", "보상", reward)
		END_TYPE.LOSE:
			msg.text = "전투에서 패배했다!"
	
	await get_tree().create_timer(2).timeout
	
	# 체력 반영 임시로 비활성화
	#PlayerData.data.hp = player_character.hp
	
	ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)

#endregion

#region 죽은 캐릭터
# 죽은 캐릭터 처리하는 함수
func _check_dead_char():
# 턴 종료 후 사망한 캐릭터 처리
	while dead_player.size() > 0:
		var dead = dead_player.pop_back()
		
		if dead == player_character:
			print("player dead")
			_battle_end(END_TYPE.LOSE)
		else:
			turn_char.erase(dead)
			dead.queue_free()
			enemy_character.erase(dead)
		
			if enemy_character.size() == 0:
				_battle_end(END_TYPE.WIN)

# 캐릭터가 사망할시 일단 배열에 넣어놓고 나중에 처리
func _on_character_died(dead : BattleCharacter):
	print(dead.name, "is dead")
	dead_player.append(dead)
#endregion
