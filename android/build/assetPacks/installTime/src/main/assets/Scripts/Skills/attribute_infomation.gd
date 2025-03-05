extends Node

var attribute : Dictionary

# 속성을 코드로 작성할 수 있게 구성 
func _ready():
	attribute["fire"] = Color.RED
	attribute["water"] = Color.BLUE
	attribute["dirt"] = Color.SADDLE_BROWN
	attribute["none"] = Color.DARK_GRAY
	
# 속성을 얻어오는 함수, 존재하지 않는 속성을 얻어올 경우 null 반환 
func get_attribute_color(name : String):
	if name in attribute.keys():
		return attribute[name]
	else:
		return null
