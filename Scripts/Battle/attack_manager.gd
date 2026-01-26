extends Node
class_name AttackManager

@onready var battle = $".." as BattleManager

var cur_skill : Dictionary

var target_info

var timer: Timer

func _ready():
	timer = Timer.new() as Timer
	add_child(timer)

# 스킬 인덱스에 해당하는 스킬 발동 
func _on_battle_use_skill(index, target, is_casting):
	# 버튼이 자동으로 비활성화되니 발동 조건 체크 X 
	# target_info는 이미 스킬 정보를 통해 가져온 정보이므로 굳이 검사X  
	target_info = target
	
	if index is Dictionary:
		cur_skill = index
	else:
		cur_skill = SkillManager.get_player_skill(index)

	if cur_skill == null or cur_skill.is_empty():
		printerr("Skill is null!")
		return

	battle.remove_cost(cur_skill)
	if is_casting:
		battle.set_casting_panel("마법 구축 중", SkillManager.get_casting_time(cur_skill, battle.attribute_bar), CastingPanel.CastingButtonType.CounterPlayer, _on_end_casting)
	else:
		skill_active(cur_skill, target_info)

func _on_end_casting(is_success):
	if is_success:
		timer.start(0.1)
		await timer.timeout
		battle.set_casting_panel("마법 시전 중", SkillManager.SKILL_ACTIVE_TIME, CastingPanel.CastingButtonType.ParryingPlayer, _on_end_spell)

func _on_end_spell(is_success):
	if is_success:
		skill_active(cur_skill, target_info)
	else:
		# 스킬 발동 실패 
		pass

func skill_active(skill: Dictionary, target):
	# 스킬의 유형에 따라 효과 결정 
	match skill.get("type", ""):
		"attack":
			do_attack(skill, target)
		"effect":
			# 일단 임시로 속성만 채우도록 
			do_effect()
		"summon":
			do_summon()
		"field":
			do_field()

	battle.set_attribute_change(skill)	
	battle.check_dead_char()
	battle.skill_used.emit()
	ViewManager.side_panel.set_hp_panel()

# 공격 함수 
func do_attack(skill: Dictionary, target):
	var apply = SkillManager.get_value(skill).get("level", 0)
	#var apply = cur_skill.get("apply", 0)
	#if not apply is float:
		#print("Attack's apply is not number!")
		#return
	# self 전용 구현 
	if target is String and target == "self":
		battle.player_character.apply_heal(apply)
	else:
		# 설정된 적 공격 
		for i in target:
			var enemy = battle.enemy_character[i]
			var damage = enemy.apply_damage(apply)
			battle.add_attack_log(battle.now_character.name, enemy.name, damage, enemy.hp)
		
func do_effect():
	pass
	
func do_summon():
	pass
	
func do_field():
	pass

