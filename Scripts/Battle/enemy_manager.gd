class_name EnemyManager extends Node

@onready var battle = $".." as BattleManager
@onready var timer = $EnemyTimer as Timer

#enum AttackStatus 
#{
	#Ready,
	#End
#}
#var status = AttackStatus.End
	#get: return status
	#set(value):
		#status = value
		#battle.attack_status_changed.emit(status)

#@onready var upper = $"../Interact/UpperPanel" as UpperPanel

var skill_info : Dictionary

var player: 
	get: return battle.player_character
var damage
	
func _ready():
	skill_info = DataManager.get_data("Skill/enemy_skill_info")

# 적의 행동 수행 
func _on_battle_scene_turn_character_changed(char: BattleCharacter):
	if char == null: return
	if char.is_player == true: return

	# 잠시 대기 
	timer.start(0.5)
	await timer.timeout
	
	# 플레이어 타겟팅 
	player.set_hp_outline_red()
	
	#timer.start(1.5)
	
	# 사용할 스킬과 그 스킬의 데미지 계산 
	var next_skill = get_next_skill(char.skills)
	print(next_skill)
	damage = get_damage_by_skill(next_skill, char.attack)
	
	# 정보 패널 띄우기
	#upper.set_panel_with_time(next_skill.name, next_skill.description % damage, 2)
	ViewManager.side_panel.set_info_panel_with_time(next_skill.name, next_skill.description % damage, 2)
	battle.add_attack_log(char.name, "Player", damage, player.hp)
	
	var cost = get_cost(next_skill)
	char.current_point -= cost.get("point", 0)
	
	# 대기했다가 공격 후 종료 
	battle.battle_panel.set_casting_panel("적 캐스팅 중", 3, true, _on_end_casting)
	#await timer.timeout

	
func _on_end_casting(is_succes):
	if is_succes:
		player.hp -= damage
		
		# 일단 한번 공격하면 턴 종료하도록
		battle.turn_end.emit()
	else:
		battle.apply_counter(battle.now_character, player)
	player.set_hp_outline_default()
	
# 적 데이터를 읽고 다음에 수행할 스킬을 반환함 
func get_next_skill(skills):
	var rng = RandomNumberGenerator.new()
	
	var rn = rng.randi_range(0, len(skills)-1)
	return skill_info[skills[rn]]
	
# skill 읽어서 데미지 계산 후 반환 
func get_damage_by_skill(skill, char_damage):
	var dmg = skill.get("damage", 0)
	var apply = skill.get("apply_type", "add")
	
	match apply:
		"add":
			return dmg + char_damage
		"multiply":
			return dmg * char_damage
		_:
			printerr("Wrong Apply Type! ", apply)
			return 0
	
# 스킬을 읽고 코스트 딕셔너리를 반환 		
func get_cost(skill):
	var cost = skill.get("cost", 0)
	if not cost is Dictionary:
		var result = {"point": cost}
		return result
	else:
		return cost
