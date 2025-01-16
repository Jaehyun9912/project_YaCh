extends Node

class_name SkillManager

var skills
var custom

func _ready():
	skills = DataManager.get_data("skill_info")

# 들어온 ID에 해당하는 스킬의 정보가 담긴 딕셔너리 반환 
func get_skill(id : String) -> Dictionary:
	if id in skills.keys():
		return skills[id]
	else:
		printerr("잘못된 스킬 ID! : " + id)
		return Dictionary()
	
	
