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
	# 스킬의 정보에 따라 발동
	var value = skill.get("value", null)
	var main_attribute = AttributeInformation.get_attribute_by_skill(skill)

	if value != null:
		do_attack(value, target, main_attribute)

	var effect_id = skill.get("effect_id", "")
	var effect_self = skill.get("effect_self", false)
	if effect_id != "":
		var effect_target = target if not effect_self else "self"
		do_effect(effect_id, effect_target)

	# TODO: summon, field 구현

	var attribute = skill.get("attribute", {})
	if attribute.size() > 0:
		battle.set_attribute_change(attribute)	
		
	battle.check_dead_char()
	battle.skill_used.emit()
	ViewManager.side_panel.set_hp_panel()

# 공격 함수 
func do_attack(value, target, attribute_type):
	# self 전용 구현 
	value *= battle.field_stat.get(attribute_type, 1.0)

	if target is String and target == "self":
		battle.player_character.apply_heal(value)
	elif target is Array:
		# 설정된 적 공격 
		for i in target:
			var enemy = battle.enemy_character[i]
			var damage = enemy.apply_damage(value)
			battle.add_attack_log(battle.now_character.name, enemy.name, damage, enemy.hp)
		
func do_effect(effect_id, target):
	# self 전용 구현 
	if target is String and target == "self":
		battle.now_character.add_buff(effect_id)
	elif target is Array:
		# 설정된 적 적용 
		for i in target:
			var enemy = battle.enemy_character[i]
			enemy.add_buff(effect_id, 1)	# 내가 남한테 건 버프는 지속시간 1턴 증가
	
func do_summon():
	#var summon_id = skill.get("summon_id", "")
	pass
	
func do_field():
	pass

