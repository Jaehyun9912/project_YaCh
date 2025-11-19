extends Node

# 플레이어의 스킬을 관리함
# 적의 스킬은 EnemyManager에서 관리함 

enum SpecialSkillType {
	COUNTER,
	PARRYING
}

var skills
var special_skills
var peer_skills

var player_skill: 
	get: return PlayerData.skills
var player_special_skill:
	get: return PlayerData.special_skills

const ACTION_POINT_ID = "point"
# 스킬 시전 시간
const SKILL_ACTIVE_TIME = 0.5
# 스킬 구축 시간 상수 (행동력 소모량에 곱해짐)
const SKILL_CASTING_CONSTANT = 0.3
# 최소 스킬 구축 시간
const SKILL_MIN_CASTING_TIME = 0.5

func _ready():
	#skills = DataManager.get_data("Skill/skill_info")
	skills = DataManager.get_data_folder("Skill/Player")
	special_skills = DataManager.get_data_folder("Skill/Special")
	peer_skills = DataManager.get_data_folder("Skill/Peer")
	
# 플레이어의 스킬 얻어오기 
func get_player_skill(index: int) -> Dictionary:
	if 0 <= index and index < len(player_skill):
		return get_skill(player_skill[index])

	print("잘못된 스킬 인덱스! : " + str(index))
	return Dictionary()

# 들어온 ID에 해당하는 스킬의 정보가 담긴 딕셔너리 반환 
func get_skill(id : String):
	if id in skills:
		return skills[id]
	else:
		printerr("잘못된 스킬 ID! : " + id)
		return null

# 스킬의 value를 반환하는 함수 (attack의 단일 value는 딕셔너리로 변환해서)
func get_value(skill: Dictionary):
	var type = skill.get("type", "")
	var value = skill.get("value", {})
	
	if type == "attack":
		if value is float or value is int:
			return {"level": value}
	return value

func check_requirement_battle(skill: Dictionary, battle_manager: BattleManager) -> bool:
	return check_requirement(skill, battle_manager.now_character.current_point, battle_manager.attribute_bar)
# 스킬이 사용 가능한지 확인하는 함수
func check_requirement(skill: Dictionary, current_action_point: int, attribute_bar) -> bool:
	# var skill = get_player_skill(player_skill_index)
	
	# 1. cost와 requirements 변환
	var requirements_dict = _get_standardized_points(skill.get("requirement", {}))
	var cost_dict = _get_standardized_points(skill.get("cost", {}))
	
	# 2. requirements를 cost의 수치 이상으로 보장
	for type in cost_dict:
		var cost_value = cost_dict[type]
		var required_value = requirements_dict.get(type, 0.0)
		requirements_dict[type] = max(required_value, cost_value)
	
	# 3. 행동력(ActionPoint) 조건 확인
	var required_ap = requirements_dict.get(ACTION_POINT_ID, -1)
	if current_action_point < required_ap:
		return false
	
	# 4. 기타 속성치(element) 조건 확인
	for type in requirements_dict:
		if type == ACTION_POINT_ID:
			continue
			
		var player_amount = attribute_bar.get_element(type)
		var required_amount = requirements_dict[type]
		
		if player_amount < required_amount:
			return false
	
	return true

# 입력된 cost 또는 requirements를 표준화된 딕셔너리 형태로 변환하기
func _get_standardized_points(data) -> Dictionary:
	if data is float or data is int:
		# 단일 float/int 값일 경우 행동력으로 간주
		return {ACTION_POINT_ID : data}
	elif data is Dictionary:
		return data
	return {}
			
# 스킬의 target 정보를 얻어오는 함수 (기본값 "one")
func get_target(skill: Dictionary):
	# var skill = get_player_skill(player_skill_index)
	if skill.get("type", "") in ["counter", "parrying"]:
		return "self"
	return skill.get("target", "one")

# 사용 가능한 특수 스킬 얻어오기
func get_useable_special_skills(special_type: SpecialSkillType, point, attribute_bar):
	var type = "counter"
	if special_type == SpecialSkillType.PARRYING:
		type = "parrying"

	var useable_skills = []
	for skill in player_special_skill:
		var info = special_skills.get(skill, {})
		
		if info.get("type") == type and check_requirement(info, point, attribute_bar):
			useable_skills.append(skill)
	return useable_skills

# 스킬의 구축 시간 계산하기
func get_casting_time(skill: Dictionary, attribute_bar):
	#(소모 행동력 X 구축상수) X (1 - (해당 속성 누적치 / 2)
	var cost = _get_standardized_points(skill.get("cost", {}))
	var action_point_cost = cost.get(ACTION_POINT_ID, 0)
	var element = AttributeInformation.get_attribute_by_skill(skill)
	var attribute_amount = attribute_bar.get_element(element)

	# 구축 시간 계산
	var casting_time = (action_point_cost * SKILL_CASTING_CONSTANT) * (1 - ((attribute_amount / attribute_bar.total_value) / 2.0))
	casting_time = max(casting_time, SKILL_MIN_CASTING_TIME)
	return casting_time

func get_peer_skill(id: String):
	return peer_skills.get(id, null)
