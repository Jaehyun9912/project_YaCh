class_name EnemyManager extends Node

@onready var timer = $EnemyTimer as Timer
var battle : BattleManager

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
var current_skill : Dictionary

var player: 
	get: return battle.player_character
var damage
	
func init(battle_manager: BattleManager):
	battle = battle_manager
	skill_info = DataManager.get_data_folder("Skill/Enemy")

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
	current_skill = get_next_skill(turn_char.skills)
	if current_skill == null:
		# 가능한 스킬이 없으면 턴 종료
		battle.turn_end.emit()
		return
	print("Enemy will Use: " + str(current_skill))

	damage = get_damage_by_skill(current_skill)

	# 정보 패널 띄우기
	#upper.set_panel_with_time(current_skill.name, current_skill.description % damage, 2)
	ViewManager.side_panel.set_info_panel_with_time(current_skill.name, current_skill.description % damage, 2)
	battle.add_attack_log(turn_char.name, "Player", damage, player.hp)

	battle.remove_cost(current_skill)

	# 대기했다가 공격 후 종료
	battle.set_casting_panel("마법 구축 중", SkillManager.get_casting_time(current_skill, battle.attribute_bar), CastingPanel.CastingButtonType.Counter, _on_end_casting)
	#await timer.timeout
	
func _on_end_casting(is_success):
	if is_success:
		timer.start(0.1)
		await timer.timeout	
		battle.set_casting_panel("마법 시전 중", SkillManager.SKILL_ACTIVE_TIME, CastingPanel.CastingButtonType.Parrying, _on_end_spell)
	else:
		battle.apply_counter(battle.now_character, player)

func _on_end_spell(is_success):
	if is_success:
		player.apply_damage(damage)
		battle.set_attribute_change(current_skill)
		# 일단 한번 공격하면 턴 종료하도록
		battle.turn_end.emit()
		battle.check_dead_char()
	else:
		pass
	battle.skill_used.emit()
	player.set_hp_outline_default()
	
# 적 데이터를 읽고 다음에 수행할 스킬을 반환함 
func get_next_skill(skills):
	var rng = RandomNumberGenerator.new()

	var useable_skills = []
	for i in skills:
		if SkillManager.check_requirement_battle(skill_info[i], battle):
			useable_skills.append(i)

	if useable_skills.size() == 0:
		return null

	var rn = rng.randi_range(0, len(useable_skills)-1)
	return skill_info[useable_skills[rn]]
	
# skill 읽어서 데미지 계산 후 반환 
func get_damage_by_skill(skill):
	var level = SkillManager.get_value(skill).get("level", 0)
	
	var stat = skill.get("stat", null)
	if stat == null:
		return level
	else:
		var char_attack = battle.now_character.attack
		match stat.get("type", ""):
			"multiply":
				level *= char_attack
			_:
				level += char_attack
	level *= stat.get("coefficient", 1)
	return level
