extends Node
class_name AttackManager

@onready var battle = $".." as BattleManager

var cur_skill : Dictionary

var target

var timer: Timer

func _ready():
	timer = Timer.new() as Timer
	add_child(timer)

# 스킬 인덱스에 해당하는 스킬 발동 
func _on_battle_use_skill(index, target_info):
	# 버튼이 자동으로 비활성화되니 발동 조건 체크 X 
	# target_info는 이미 스킬 정보를 통해 가져온 정보이므로 굳이 검사X  
	target = target_info
	
	cur_skill = SkillManager.get_player_skill(index)
	battle.remove_cost(cur_skill)

	battle.set_casting_panel("마법 구축 중", SkillManager.get_casting_time(cur_skill, battle.attribute_bar), CastingPanel.CastingButtonType.CounterPlayer, _on_end_casting)

func _on_end_casting(is_success):
	if is_success:
		timer.start(0.1)
		await timer.timeout
		battle.set_casting_panel("마법 시전 중", SkillManager.SKILL_ACTIVE_TIME, CastingPanel.CastingButtonType.ParryingPlayer, _on_end_spell)

func _on_end_spell(is_success):
	if is_success:
			# 스킬의 유형에 따라 효과 결정 
		match cur_skill.get("type", ""):
			"attack":
				do_attack()
			"effect":
				# 일단 임시로 속성만 채우도록 
				do_effect()
			"summon":
				do_summon()
			"field":
				do_field()

		battle.set_effect(cur_skill)	
	#var element = cur_skill.get("element", {})
	#if element.has("type"):
			#battle.attribute_bar.add_value(element["type"], element["amount"])
		# var effect = cur_skill.get("effect", {})
		# for type in effect:
		# 	if type == SkillManager.ACTION_POINT_ID:
		# 		battle.now_character.point += effect[type]
		# 	else:
		# 		battle.attribute_bar.add_value(type, effect[type])
	else:
		# 스킬 발동 실패 
		pass

# 공격 함수 
func do_attack():
	var apply = SkillManager.get_value(cur_skill).get("level", 0)
	#var apply = cur_skill.get("apply", 0)
	#if not apply is float:
		#print("Attack's apply is not number!")
		#return
	# self 전용 구현 
	if target is String and target == "self":
		battle.player_character.hp -= apply
	else:
		# 설정된 적 공격 
		for i in target:
			var enemy = battle.enemy_character[i]
			battle.add_attack_log(battle.now_character.name, enemy.name, apply, enemy.hp)
			enemy.hp -= apply
		
func do_effect():
	pass
	
func do_summon():
	pass
	
func do_field():
	pass

