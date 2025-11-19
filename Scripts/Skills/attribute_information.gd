extends Node

var attribute : Dictionary

const NONE_ATTRIBUTE = "none"

func _ready():
	# attribute["fire"] = Color.RED
	# attribute["water"] = Color.BLUE
	# attribute["dirt"] = Color.SADDLE_BROWN
	# attribute["none"] = Color.DARK_GRAY
	var attr_data = DataManager.get_data("attribute_info.json")
	if attr_data == null:
		printerr("Attribute info data load failed!")
		attribute = {}
	else:
		attribute = {}
		for att in attr_data:
			if att.has("name"):
				attribute[att["name"]] = Color(att.get("color", "#000000"))
			
	
# 속성을 얻어오는 함수, 존재하지 않는 속성을 얻어올 경우 null 반환 
func get_attribute_color(attribute_name : String):
	if attribute_name in attribute.keys():
		return attribute[attribute_name]
	else:
		return null
		
# 스킬 정보를 넣으면 자동으로 가장 큰 값을 가진 속성의 이름을 반환하는 함수
func get_attribute_by_skill(skill: Dictionary):
	var effects = skill.get("effect", {})
	var large = "none"
	for ele in effects:
		if ele == SkillManager.ACTION_POINT_ID:
			continue
		if effects[ele] > effects.get(large, 0):
			large = ele
	return large
	# return get_attribute_color(effects.get(large, "none"))
