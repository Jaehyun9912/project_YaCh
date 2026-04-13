extends Node
class_name AttackManager

@onready var battle = $".." as BattleManager

var cur_skill : SkillData

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
	
	if index is SkillData:
		cur_skill = index
	elif index is Dictionary:
		cur_skill = SkillData.from_dict("temp", index)
	else:
		cur_skill = SkillManager.get_player_skill(index)

	if cur_skill == null:
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

func skill_active(skill: SkillData, target):
	# 스킬의 정보에 따라 발동
	var execution = skill.execution

	# 1. 액션들 실행 (데미지, 버프 등)
	for action in execution.actions:
		if randf() > action.chance:
			continue
			
		match action.type:
			"damage":
				var value = calculate_formula(action.formula, battle.now_character)
				do_attack(value, target, action.element)
			"buff", "debuff":
				do_effect(action.effect_id, target)
			"summon":
				do_summon()
			"field":
				do_field()

	# 2. 원소 수치 변화 적용
	if execution.element.size() > 0:
		battle.set_attribute_change(execution.element)	
		
	battle.check_dead_char()
	battle.skill_used.emit()
	ViewManager.side_panel.set_hp_panel()

func calculate_formula(formula: SkillData.Execution.Action.Formula, caster: BattleCharacter) -> float:
	var stat_val = caster.stat_manager.get_stat(formula.scaling_stat, 0.0)
	return formula.base + (stat_val * formula.multiplier)

# 공격 함수 
func do_attack(value: float, target, attribute_type: String):
	# 필드 보정 적용 (예: 속성 배율)
	value *= battle.field_stat.get(attribute_type, 1.0)

	if target is String and target == "self":
		battle.player_character.apply_heal(value)
	elif target is Array:
		# 설정된 적 공격 
		for i in target:
			var enemy = battle.enemy_character[i]
			var damage = enemy.apply_damage(value)
			battle.add_attack_log(battle.now_character.name, enemy.name, damage, enemy.hp)
		
func do_effect(effect_id: String, target):
	if effect_id == "": return
	
	# target이 "self"인 경우 또는 배열인 경우 처리
	if target is String and target == "self":
		battle.now_character.add_buff(effect_id)
	elif target is Array:
		for i in target:
			var enemy = battle.enemy_character[i]
			enemy.add_buff(effect_id, 1)	# 상대에게 거는 버프는 지속시간 보정
	
func do_summon():
	pass
	
func do_field():
	pass
