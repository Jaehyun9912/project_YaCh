extends Node

var attribute : Dictionary

# 속성을 코드로 작성할 수 있게 구성 
func _ready():
	attribute["fire"] = Color.RED
	attribute["water"] = Color.BLUE
	attribute["dirt"] = Color.SADDLE_BROWN
	attribute["none"] = Color.DARK_GRAY
	
# 속성을 얻어오는 함수, 존재하지 않는 속성을 얻어올 경우 null 반환 
func get_attribute_color(attribute_name : String):
	if attribute_name in attribute.keys():
		return attribute[attribute_name]
	else:
		return null
		
# 스킬 정보를 넣으면 자동으로 가장 큰 값을 가진 속성 색을 반환하는 함수 
func get_attribute_color_by_skill(skill: Dictionary):
	var effects = skill.get("effect", {})
	var large = "none"
	for ele in effects:
		if ele == SkillManager.ACTION_POINT_ID:
			continue
		if effects[ele] > effects.get(large, 0):
			large = ele

	return get_attribute_color(effects.get(large, "none"))
