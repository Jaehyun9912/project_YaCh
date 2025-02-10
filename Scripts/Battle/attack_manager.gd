extends Node
class_name AttackManager

@onready var battle = $".." as BattleManager
@onready var skill_manager = $"../SkillManager" as SkillManager

var cur_skill : Dictionary

func _ready():
	battle.use_skill.connect(use_skill)

# 스킬 인덱스에 해당하는 스킬 발동 
func use_skill(index):
	# 버튼이 자동으로 비활성화되니 굳이 체크하지 않음 
	#if not skill_manager.check_requirement(index, battle.turn_cost):
		#print("No Cost")
		#return
	
	cur_skill = skill_manager.get_player_skill(index)
	
	skill_manager.remove_cost(index)
	
	# 스킬의 유형에 따라 효과 결정 
	match cur_skill.get("type", ""):
		"attack":
			do_attack()
			# 일단 임시로 전체 공격 
			#for i in enemy_character:
				#i.hp -= cur_skill_info["attack"]
		"effect":
			# 일단 임시로 속성만 채우도록 
			do_effect()
			#$Interact/AttributeBar.add_value(cur_skill_info["attribute"]["type"], cur_skill_info["attribute"]["amount"])
		"summon":
			do_summon()
		"field":
			do_field()
	
	var element = cur_skill.get("element", {})
	if element.has("type"):
			$"../Interact/AttributeBar".add_value(element["type"], element["amount"])
	

func do_attack():
	#var target = get_value("target", 1)
	#var apply = get_value("apply")
	#if apply == null: return
	pass
	
func do_effect():
	pass
	
func do_summon():
	pass
	
func do_field():
	pass

