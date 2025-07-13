class_name EnemyManager extends Node

@onready var battle = $".." as BattleManager
@onready var timer = $EnemyTimer as Timer

#@onready var upper = $"../Interact/UpperPanel" as UpperPanel

var skill_info : Dictionary

var player: 
	get: return battle.player_character
	
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
	battle.player_character.set_hp_outline_red()
	timer.start(1.5)
	
	# 사용할 스킬과 그 스킬의 데미지 계산 
	var next_skill = get_next_skill(char.skills)
	print(next_skill)
	var damage = get_damage_by_skill(next_skill, char.attack)
	
	# 정보 패널 띄우기
	#upper.set_panel_with_time(next_skill.name, next_skill.description % damage, 2)
	SidePanel.set_info_panel_with_time(next_skill.name, next_skill.description % damage, 2)
	battle.add_attack_log(char.name, "Player", damage, battle.player_character.hp)
	
	var cost = get_cost(next_skill)
	char.current_point -= cost.get("point", 0)
	
	# 대기했다가 공격 후 종료 
	await timer.timeout
	battle.player_character.hp -= damage
	battle.player_character.set_hp_outline_default()
	#var skill = 
	
	battle.turn_end.emit()
	
	
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
