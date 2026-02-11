extends Node

var attribute : Dictionary

const NONE_ATTRIBUTE = "none"

func _ready():
	# attribute["fire"] = Color.RED
	# attribute["water"] = Color.BLUE
	# attribute["dirt"] = Color.SADDLE_BROWN
	# attribute["none"] = Color.DARK_GRAY
	attribute = DataManager.get_data("attribute_info.json")
	if attribute == null:
		printerr("Attribute info data load failed!")
		attribute = {}
			
func get_attribute(att_name: String):
	return attribute.get(att_name, null)
	
# 속성을 얻어오는 함수, 존재하지 않는 속성을 얻어올 경우 null 반환 
func get_attribute_color(attribute_name : String):
	var att_info = get_attribute(attribute_name)
	if att_info == null:
		return null
	var color_str = att_info.get("color", null)
	if color_str == null:
		return null
	return Color(color_str)

		
# 스킬 정보를 넣으면 자동으로 가장 큰 값을 가진 속성의 이름을 반환하는 함수
func get_attribute_by_skill(skill: Dictionary):
	var attribute_change = skill.get("attribute", {})
	if attribute_change.size() == 0:
		return NONE_ATTRIBUTE
		
	var large = ""
	for ele in attribute_change:
		if ele == SkillManager.ACTION_POINT_ID:
			continue
		if attribute_change[ele] > attribute_change.get(large, 0):
			large = ele
	return large
	# return get_attribute_color(effects.get(large, "none"))
