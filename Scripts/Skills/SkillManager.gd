extends Node
class_name SkillManager

@onready var manager := $".."
@onready var attribute := $"../Interact/AttributeBar"

var skills
var player_skill

func _ready():
	skills = DataManager.get_data("skill_info")
	player_skill = PlayerData.skills
	
# 플레이어의 스킬 얻어오기 
func get_player_skill(index: int):
	return get_skill(player_skill[index])

# 들어온 ID에 해당하는 스킬의 정보가 담긴 딕셔너리 반환 
func get_skill(id : String):
	if id in skills:
		return skills[id]
	else:
		printerr("잘못된 스킬 ID! : " + id)
		return null

# 플레이어의 스킬이 사용 가능한지 확인하기 (원소는 알아서 가져옴)  
func check_requirement(player_skill_index: int, current_point: int):
	var skill = get_player_skill(player_skill_index)
	
	# cost 값이 숫자이면 Dictionary로 변환
	var cost = skill.get("cost", {})
	if not cost is Dictionary:
		cost = {"point": cost}
	
	# requirements가 설정되지 않았거나 cost보다 낮으면 cost와 동일하게 설정
	var requirements = skill.get("requirement", cost)
	if not requirements is Dictionary:
		requirements = {"point": requirements}
	requirements["point"] = max(requirements["point"], cost["point"])
	
	# 요구 조건을 충족하는지 확인
	if current_point < requirements.get("point", 0):
		return false  # 행동력이 부족함
	
	# 원소 확인 
	if "element" in requirements:
		var required_element = requirements.get("element", {}).duplicate(true)
		var cost_element = cost.get("element", {})
		
		# cost에 있지만 requirements에 없는 요소 추가
		for type in cost_element:
			if type not in required_element:
				required_element[type] = cost_element[type]
				
		# requirement가 cost의 수치보다 낮으면 cost로 설정	
		for type in required_element:
			required_element[type] = max(required_element[type], cost_element.get(type, 0))
		
		# 요구 속성치를 가져옴
		for type in required_element:
			var player_amount = attribute.get_element(type)
			var amount = required_element[type]
			
			# 만약 현재 필드 속성치보다 요구치가 높으면 실패 
			if amount > player_amount:
				return false
	
	return true  # 모든 조건 충족
	
# 코스트 제거하기 
func remove_cost(player_skill_index: int):
	var skill = get_player_skill(player_skill_index)
	var cost = skill.get("cost", {})
	
	if not cost is Dictionary:
		manager.turn_cost -= cost
		return
		
	manager.turn_cost -= cost.get("point", 0)
	if "element" in cost:
		var element = cost.get("element", {})
		for e in element:
			attribute.remove_value(e, element[e])
