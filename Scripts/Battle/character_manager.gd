class_name CharacterManager extends Node

signal character_died(dead_char: BattleCharacter, is_player: bool, is_all_enemies_dead : bool)
signal log_requested(msg: String)

# 캐릭터들의 정보를 담은 리스트
var turn_char: Array[BattleCharacter]
var player_character : BattleCharacter
var ally_character : Array[BattleCharacter]
var enemy_character : Array[BattleCharacter]

# 죽은 캐릭터 행동 이후 처리용 
var dead_player: Array[BattleCharacter]

# 각 그룹의 수 
var enemy_count: 
	get: return len(enemy_character)
var ally_count: 
	get: return len(ally_character)

var total_speed = 0

func init(battle_characters: Array[Node], map_data: Dictionary, total_point: int):
	# turn_char 초기화
	turn_char.clear()
	for node in battle_characters:
		if node is BattleCharacter:
			turn_char.append(node)
			
	enemy_character.clear()
	ally_character.clear()
	
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
			if map_data.has("enemys") and idx < map_data["enemys"].size():
				var data = map_data["enemys"][idx]
				i.set_character(data, "Enemy." + data.get("tag", "Unknown"))
				idx += 1
			
		if not i.character_died.is_connected(_on_character_died):
			i.character_died.connect(_on_character_died)
	
	ally_character.append(player_character)
	update_turn_point(total_point)

# 속도에 따른 행동력 계산 후 정렬에 반영 
func update_turn_point(total_point: int):
	total_speed = 0
	for i in turn_char:
		total_speed += i.speed
		
	for i in turn_char:
		i.point = i.speed / total_speed * total_point
	
	turn_char.sort_custom(func(a, b): return a.speed > b.speed)

# 죽은 캐릭터 처리하는 함수
func check_dead_char() -> bool:
# 턴 종료 후 사망한 캐릭터 처리
	while dead_player.size() > 0:
		var dead = dead_player.pop_back()
		log_requested.emit("%s 사망" % dead.name)
		
		# 죽은 캐릭터가 플레이어인지 확인
		if dead == player_character:
			print("player dead")
			character_died.emit(dead, true, false)
			return true
		else:
			turn_char.erase(dead)
			dead.queue_free()
			enemy_character.erase(dead)
		
			# 적들이 모두 죽었는지 확인
			if enemy_character.size() == 0:
				character_died.emit(dead, false, true)
				return true
	return false

# 캐릭터가 사망할시 일단 배열에 넣어놓고 나중에 처리
func _on_character_died(dead : BattleCharacter):
	print(dead.name, "is dead")
	dead_player.append(dead)
