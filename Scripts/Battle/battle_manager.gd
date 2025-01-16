extends Node3D
class_name BattleManager

# 턴 변경을 알리는 신호
signal turn_character_changed(new_character : BattleCharacter)

# 턴 행동을 완료했음을 알리는 신호
signal turn_end

# 행동력 포인트 (나중에 변수로 변경해도 무방)
const BASE_POINT = 50
const ADDITIONAL_POINT = 50

# 가장 적은 포인트를 사용하는 행동 (자동 턴 넘기기 용)
var min_point_use = 1
# 턴 대기 타이머
@onready var enemy_timer = $EnemyTimer as Timer
# 스킬 매니저
@onready var skill_manager = $SkillManager as SkillManager

# 캐릭터들의 정보를 담은 리스트
@onready var turn_char := get_tree().get_nodes_in_group("battle_characters").duplicate()
var player_character : BattleCharacter
var enemy_character : Array[BattleCharacter]

# 현재 턴인 캐릭터의 정보
var now_character: BattleCharacter

# 죽은 캐릭터 행동 이후 처리용 
var dead_player: Array[BattleCharacter]

var map_data : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	await turn_end
	
	_battle()
	
# 전투 전 설정
# 맵 정보 불러오기, 캐릭터 정보 할당하기, 행동력 구해주고 턴 순서에 맞추어 정렬하기
func _battle_set():
	var total := 0
	
	# 맵 정보 불러오기
	var map_name = "World/" + ViewManager.now_map_name
	map_data = DataManager.get_data(map_name)
	
	# 필수 정보 확인하기 
	if map_data.size() == 0:
		printerr("No MapData!")
		ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
	const CHECK = ["enemys", "attribute"]
	for i in CHECK:
		if map_data.has(i) == false:
			printerr("No " + i)
			ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
			return
	
	# 속성 정보 세팅 
	$Interact/AttributeBar.init(map_data["attribute"])
	
	var idx = 0
	# 행동력 총합 및 캐릭터 정보 설정하기.
	for i in turn_char:
		if i.is_player == true:
			player_character = i
			player_character.set_character(PlayerData.data)
		else:
			enemy_character.append(i)
			i.set_character(map_data["enemys"][idx])
			idx += 1
			
		i.character_died.connect(_on_character_died)
		total += i.speed
		
	# 캐릭터별 행동력 설정하고 턴 순서 설정하기 
	for i in turn_char:
		i.point = BASE_POINT + i.speed / total * ADDITIONAL_POINT
		#print(i.speed, " ", total)
		print(i.name, " ", i.speed / total * ADDITIONAL_POINT) 
	
	turn_char.sort_custom(func(a, b): return a.speed > b.speed)

# 전투를 관리하는 함수 (await 이용) 
func _battle():
	_battle_set()
	
	while true:
		for i in turn_char:
			now_character = i
			turn_character_changed.emit(i)
			
			# 플레이어 턴 
			if i.is_player == true:
				print("player turn")
				
				# turn_end 신호가 emit 할때까지 대기
				await turn_end
			
			# 적 턴 
			else:
				print("enemy turn")	
				enemy_timer.start()
				await enemy_timer.timeout
				player_character.hp -= 1
				# 적 AI
			
			_check_dead_char()
						
			print("turn end")

# 버튼 눌렀을때
func on_battle_panel_skill_actived(index : BattlePanel.Buttons):
	match index:
		# 버튼에 해당하는 효과 발동 
		BattlePanel.Buttons.CENTER:
			print("center")
			turn_end.emit()
		BattlePanel.Buttons.SKILL1:
			use_skill(0)
		BattlePanel.Buttons.SKILL2:
			use_skill(1)
		BattlePanel.Buttons.SKILL3:
			use_skill(2)
		BattlePanel.Buttons.SKILL4:
			use_skill(3)
		BattlePanel.Buttons.RUN:
			_battle_end(0)
				
	if now_character.current_point < min_point_use:
			turn_end.emit()
			
	_check_dead_char()

# 스킬 인덱스에 해당하는 스킬 발동 
func use_skill(index):
	# 플레이어의 스킬을 가져와서 그에 해당하는 스킬 정보를 얻어옴 
	var cur_skill = PlayerData.skills[index]
	var cur_skill_info = DataManager.get_skill_data(cur_skill)
	
	# 스킬의 코스트 감소만큼 감소시키기 
	now_character.current_point -= cur_skill_info["cost"]
	# 스킬의 유형에 따라 효과 결정 
	match cur_skill_info["type"]:
		"attack":
			# 일단 임시로 전체 공격 
			for i in enemy_character:
				i.hp -= cur_skill_info["attack"]
		"magic":
			# 일단 임시로 속성만 채우도록 
			$Interact/AttributeBar.add_value(cur_skill_info["attribute"]["type"], cur_skill_info["attribute"]["amount"])

# 죽은 캐릭터 처리하는 함수
func _check_dead_char():
# 턴 종료 후 사망한 캐릭터 처리
	while dead_player.size() > 0:
		var dead = dead_player.pop_back()
		
		if dead == player_character:
			print("player dead")
			_battle_end(2)
		else:
			turn_char.erase(dead)
			dead.queue_free()
			enemy_character.erase(dead)
		
			if enemy_character.size() == 0:
				_battle_end(1)
	
# 일단 임시로 정수형태로 해놓았으나 나중에 컨디션이나 태그를 받도록 수정할 예정
func _battle_end(type):
	# 도망, 적 전부 처치 전투 종료 구현하기 
	
	# 모든 버튼 비활성화 
	ViewManager.current_panel.get_node("BattlePanel").set_all_button(false)
	var msg = $Interact/EndMsg as Label
	
	match type:
		0:
			msg.text = "전투에서 도망쳤다!"
		1:
			msg.text = "전투에서 승리했다!"
			
			# 보상 부여
			if map_data.has("rewards") and map_data["rewards"].has("item"):
				for i in map_data["rewards"]["item"]:
					if (i.has("id") == false):
						printerr("No Item ID in rewards!")
					elif (i.has("count") == false):
						PlayerData.add_new_item(i["id"], 1)
					else:
						PlayerData.add_new_item(i["id"], i["count"])
		2:
			msg.text = "전투에서 패배했다!"
	
	await get_tree().create_timer(2).timeout
	
	# 체력 반영 임시로 비활성화
	#PlayerData.data.hp = player_character.hp
	
	ViewManager.load_world(ViewManager.old_map, ViewManager.old_panel)
	

# 캐릭터가 사망할시 일단 배열에 넣어놓고 나중에 처리
func _on_character_died(dead : BattleCharacter):
	print(dead.name, "is dead")
	dead_player.append(dead)
