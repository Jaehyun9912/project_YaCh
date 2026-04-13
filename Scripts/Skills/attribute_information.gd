extends Node

var attribute : Dictionary

const NONE_ATTRIBUTE = "none"

func _ready():
	# attribute["fire"] = Color.RED
	# attribute["water"] = Color.BLUE
	# attribute["dirt"] = Color.SADDLE_BROWN
	# attribute["none"] = Color.DARK_GRAY
	# attribute = DataManager.get_data_folder("Attributes")
	attribute = DataManager.load_datas_dict("Attribute", AttributeData)
	if attribute == null:
		printerr("Attribute info data load failed!")
		attribute = {}
			
func get_attribute(att_name: String) -> AttributeData:
	return attribute.get(att_name, null)
	
## 스킬 정보를 넣으면 해당 스킬의 주 속성(첫 번째 액션의 속성) ID를 반환하는 함수
func get_attribute_by_skill(skill: SkillData) -> String:
	if skill.execution.actions.size() > 0:
		return skill.execution.actions[0].element
	return NONE_ATTRIBUTE
