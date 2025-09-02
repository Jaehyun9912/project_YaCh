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
	skill_info = DataManager.get_data_folder("Skill/Enemy")
	#print(skill_info)

# 적의 행동 수행 
func _on_battle_scene_turn_character_changed(turn_char: BattleCharacter):
	if turn_char == null: return
	if turn_char.is_player == true: return

	# 잠시 대기 
	timer.start(1)
	await timer.timeout
	
	# 플레이어 타겟팅 
	player.set_hp_outline_red()
	
	#timer.start(1.5)
	
	# 사용할 스킬과 그 스킬의 데미지 계산 
	var next_skill = get_next_skill(turn_char.skills)
	print(next_skill)
	damage = SkillManager.get_value(next_skill).get("level", 0)
	
	# 정보 패널 띄우기
	#upper.set_panel_with_time(next_skill.name, next_skill.description % damage, 2)
	ViewManager.side_panel.set_info_panel_with_time(next_skill.name, next_skill.description % damage, 2)
	battle.add_attack_log(turn_char.name, "Player", damage, player.hp)
	
	var cost = get_cost(next_skill)
	turn_char.current_point -= cost.get("point", 0)
	
	# 대기했다가 공격 후 종료 
	battle.battle_panel.set_casting_panel("적 캐스팅 중", 2, CastingPanel.CastingButtonType.Counter, _on_end_casting)
	#await timer.timeout
	
func _on_end_casting(is_success):
	if is_success:
		battle.battle_panel.set_casting_panel("마법 시전 중", 1, CastingPanel.CastingButtonType.Parrying, _on_end_spell)
	else:
		battle.apply_counter(battle.now_character, player)

func _on_end_spell(is_success):
	if is_success:
		player.hp -= damage
			
		# 일단 한번 공격하면 턴 종료하도록
		battle.turn_end.emit()
	else:
		pass
	player.set_hp_outline_default()
	
# 적 데이터를 읽고 다음에 수행할 스킬을 반환함 
func get_next_skill(skills):
	var rng = RandomNumberGenerator.new()
	
	var rn = rng.randi_range(0, len(skills)-1)
	return skill_info[skills[rn]]
	
# skill 읽어서 데미지 계산 후 반환 
# func get_damage_by_skill(skill):
# 	var value = skill.get("value", 0)
# 	if value is int or value is float:
# 		return value
# 	elif value is Dictionary:
# 		return value.get("level", 0)
	# var dmg = skill.get("damage", 0)
	# var apply = skill.get("apply_type", "add")
	
	# match apply:
	# 	"add":
	# 		return dmg + char_damage
	# 	"multiply":
	# 		return dmg * char_damage
	# 	_:
	# 		printerr("Wrong Apply Type! ", apply)
	# 		return 0
	
# 스킬을 읽고 코스트 딕셔너리를 반환 		
func get_cost(skill):
	var cost = skill.get("cost", 0)
	if not cost is Dictionary:
		var result = {"point": cost}
		return result
	else:
		return cost
