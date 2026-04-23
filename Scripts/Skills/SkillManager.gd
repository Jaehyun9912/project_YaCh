## [SkillManager] 플레이어, 동료, 특수 스킬 및 버프 데이터를 관리하는 싱글톤 매니저입니다.
extends Node

# 로드된 데이터 저장소 (Dictionary<String, SkillData/EffectData>)
var skills: Dictionary = {}          # 일반 스킬 정보
var special_skills: Dictionary = {}  # 특수 스킬 정보
var peer_skills: Dictionary = {}     # 동료 스킬 정보
var buff_data: Dictionary = {}       # 버프(EffectData) 정보

# 플레이어 현재 보유 스킬 ID 리스트 (PlayerData 참조)
var player_skill: Array:
	get: return PlayerData.data.get("skills", [])

var player_special_skill: Array:
	get: return PlayerData.data.get("special_skills", [])

var player_peer_skill_id: String:
	get: return PlayerData.data.get("peer_skill", "")

# 상수 설정
const ACTION_POINT_ID = "point"
const SKILL_ACTIVE_TIME = 0.5
const SKILL_CASTING_CONSTANT = 0.3
const SKILL_MIN_CASTING_TIME = 0.5

func _ready():
	# 1. JSON 데이터 로드
	skills = DataManager.load_datas_dict("Skill/Player", SkillData)
	var enemy_skills = DataManager.load_datas_dict("Skill/Enemy", SkillData)
	
	skills.merge(enemy_skills) # Enemy 스킬도 SkillManager에서 관리함
	special_skills = DataManager.load_datas_dict("Skill/Special", SkillData)
	peer_skills = DataManager.load_datas_dict("Skill/Peer", SkillData)
	buff_data = DataManager.load_datas_dict("Effect", EffectData)

## 버프 ID로 실시간 버프 인스턴스(SkillBuff)를 생성하여 반환
func get_buff(id: String) -> SkillBuff:
	if id in buff_data:
		return SkillBuff.new(buff_data[id])
	printerr("[SkillManager] 잘못된 버프 ID! : ", id)
	return null

## 플레이어 인덱스로 스킬 데이터 반환
func get_player_skill(index: int) -> SkillData:
	if 0 <= index and index < player_skill.size():
		return get_skill(player_skill[index])
	printerr("[SkillManager] 잘못된 스킬 인덱스! : ", index)
	return null

## ID로 일반 스킬 데이터 반환
func get_skill(id: String) -> SkillData:
	if id in skills:
		return skills[id]
	printerr("[SkillManager] 잘못된 스킬 ID! : ", id)
	return null

## 전투 상황에서 스킬 사용 가능 여부 확인
func check_requirement_battle(skill: SkillData, battle_manager: BattleManager) -> bool:
	return check_requirement(skill, battle_manager.now_character.current_point, battle_manager.attribute_bar)

## 스킬 발동 조건(비용 및 요구 능력치) 확인
func check_requirement(skill: SkillData, current_ap: int, attribute_bar: Node) -> bool:
	var req = skill.requirements
	
	# 1. 행동력(ActionPoint) 체크
	var cost_ap = req.cost.get(ACTION_POINT_ID, 0)
	if current_ap < cost_ap:
		return false
		
	# 2. 추가 조건(Condition) 체크
	for cond in req.conditions:
		if cond.stat != "":
			var player_stat_val = attribute_bar.get_element(cond.stat)
			var target_val = cond.value
			
			match cond.op:
				">": if not (player_stat_val > target_val): return false
				"<": if not (player_stat_val < target_val): return false
				"==": if not (player_stat_val == target_val): return false
				">=": if not (player_stat_val >= target_val): return false
				"<=": if not (player_stat_val <= target_val): return false
	
	# 3. 추가 자원 비용 체크 (행동력 제외)
	for res_name in req.cost:
		if res_name == ACTION_POINT_ID: continue
		if attribute_bar.get_element(res_name) < req.cost[res_name]:
			return false
			
	return true

## 스킬의 타겟 범위 반환 (특수 스킬 예외 처리 포함)
func get_target(skill: SkillData) -> String:
	# 특수 타입(카운터/패링)은 무조건 자신 대상
	if skill.display.owner_type == "special":
		return "self"
	return skill.execution.target

## 현재 사용 가능한 특수 스킬 목록 반환
func get_useable_special_skills(special_type: SkillData.SkillType, ap: int, attribute_bar: Node) -> Array[String]:
	var useable_skills: Array[String] = []
	
	for skill_id in player_special_skill:
		var skill: SkillData = special_skills.get(skill_id, null)
		if not skill: continue
		
		# 요구 조건 및 타입 확인
		if skill.requirements.category == special_type and check_requirement(skill, ap, attribute_bar):
			useable_skills.append(skill_id)
			
	return useable_skills

## 스킬의 구축(캐스팅) 시간 계산
func get_casting_time(skill: SkillData, attribute_bar: Node) -> float:
	# 공식: (소모 행동력 X 구축상수) X (1 - (해당 속성 누적치 / 전체 누적치 / 2))
	var cost_ap = skill.requirements.cost.get(ACTION_POINT_ID, 0)
	var element = AttributeInformation.get_attribute_by_skill(skill)
	var attribute_amount = attribute_bar.get_element(element)

	var casting_time = (cost_ap * SKILL_CASTING_CONSTANT) * (1.0 - ((attribute_amount / attribute_bar.total_value) / 2.0))
	return max(casting_time, SKILL_MIN_CASTING_TIME)

## 동료 스킬 데이터 반환
func get_peer_skill(id: String) -> SkillData:
	return peer_skills.get(id, null)
