extends Node
class_name AttackManager

@onready var battle = $".." as BattleManager

var cur_skill : Dictionary

var target

# 스킬 인덱스에 해당하는 스킬 발동 
func _on_battle_use_skill(index, target_info):
	# 버튼이 자동으로 비활성화되니 굳이 체크하지 않음 
	#if not skill_manager.check_requirement(index, battle.turn_cost):
		#print("No Cost")
		#return
	
	# target_info는 이미 스킬 정보를 통해 가져온 정보이므로 굳이 검사X  
	target = target_info
	
	cur_skill = SkillManager.get_player_skill(index)
	battle.remove_cost(cur_skill)
	
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
	
	var element = cur_skill.get("element", {})
	if element.has("type"):
			battle.attrubute_bar.add_value(element["type"], element["amount"])
	

# 공격 함수 
func do_attack():
	var apply = cur_skill.get("apply", 0)
	if not apply is float:
		print("Attack's apply is not number!")
		return
	
	# 설정된 적 공격 
	if len(target) > 0:
		for i in target:
			battle.enemy_character[i].hp -= apply
	# count = 0이면 모든 적 대상 (취소는 아예 호출되지 않으므로 )
	else:
		for i in battle.enemy_character:
			i.hp -= apply
	
func do_effect():
	pass
	
func do_summon():
	pass
	
func do_field():
	pass

