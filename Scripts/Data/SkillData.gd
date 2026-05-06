## [SkillData] 스킬 정보를 담는 데이터 클래스입니다.
class_name SkillData
extends RefCounted

enum SkillType {
	NORMAL,
	SPECIAL_PARRY,
	SPECIAL_COUNTER,
	PEER
}

## UI 및 표시용 데이터 클래스
class Display:
	var name: String = ""              # 스킬 이름
	var description: String = ""       # 스킬 설명
	var owner_type: String = "player"  # 소유자 타입 (player, enemy, peer, special)
	var icon: String = "res://icon.svg" # 아이콘 경로

	static func from_dict(dict: Dictionary) -> Display:
		var d = Display.new()
		d.name = dict.get("name", "")
		d.description = dict.get("description", "")
		d.owner_type = dict.get("owner_type", "player")
		d.icon = dict.get("icon", "res://icon.svg")
		return d

## 스킬 사용 시 필요한 조건 및 자원 클래스
class Requirements:
	## 특정 능력치 비교 조건 클래스
	class Cond:
		var stat: String = ""          # 체크할 능력치 이름
		var op: String = "=="          # 비교 연산자 (>, <, == 등)
		var value: Variant = 0         # 비교 대상 값

		static func from_dict(dict: Dictionary) -> Cond:
			var c = Cond.new()
			c.stat = dict.get("stat", "")
			c.op = dict.get("op", "==")
			c.value = dict.get("value", 0)
			return c

	var cost: Dictionary = {}          # 소모 자원 (예: {"mana": 10})
	var conditions: Array[Cond] = []   # 발동 조건 목록 (AND 연산)
	var cooldown: int = 0              # 재사용 대기시간 (턴 단위)
	var category: SkillType = SkillType.NORMAL # 스킬 카테고리 (normal, special_parry, special_counter, peer)

	static func from_dict(dict: Dictionary) -> Requirements:
		var r = Requirements.new()
		r.cost = dict.get("cost", {})
		
		# 하위 호환성 유지: 단일 객체인 경우와 배열인 경우 모두 처리
		var cond_data = dict.get("condition", [])
		if cond_data is Dictionary:
			r.conditions.append(Cond.from_dict(cond_data))
		elif cond_data is Array:
			for c_dict in cond_data:
				r.conditions.append(Cond.from_dict(c_dict))
				
		r.cooldown = dict.get("cooldown", 0)
		r.category = dict.get("category", SkillType.NORMAL)
		return r

## 스킬 실행 시 수행될 액션 정보 클래스
class Execution:
	## 구체적인 개별 액션 (데미지, 버프 등) 클래스
	class Action:
		## 수치 계산식 클래스
		class Formula:
			var base: float = 0        # 기본값
			var scaling_stat: String = "attack" # 계수 적용 능력치
			var multiplier: float = 1.0 # 계수 배율

			static func from_dict(dict: Dictionary) -> Formula:
				var f = Formula.new()
				f.base = dict.get("base", 0)
				f.scaling_stat = dict.get("scaling_stat", "attack")
				f.multiplier = dict.get("multiplier", 1.0)
				return f

		var type: String = "damage"    # 액션 타입 (damage, buff, debuff, summon, field)
		var formula: Formula           # 계산식
		var element: String = "none"   # 속성 타입 (데미지 계산 등에 사용)
		var effect_id: String = ""     # 상태이상/이펙트 ID
		var chance: float = 1.0        # 발동 확률 (0~1)

		static func from_dict(dict: Dictionary) -> Action:
			var a = Action.new()
			a.type = dict.get("type", "damage")
			a.formula = Formula.from_dict(dict.get("formula", {}))
			a.element = dict.get("element", "none")
			a.effect_id = dict.get("effect_id", "")
			a.chance = dict.get("chance", 1.0)
			return a

	var target: String = "one"         # 대상 범위 (one, all, self, team, field)
	var actions: Array[Action] = []    # 수행할 액션 리스트
	var element: Dictionary = {}       # 스킬 실행 결과 원소 수치 변화량

	static func from_dict(dict: Dictionary) -> Execution:
		var e = Execution.new()
		e.target = dict.get("target", "one")
		for a_dict in dict.get("actions", []):
			e.actions.append(Action.from_dict(a_dict))
		e.element = dict.get("element", {})
		return e

var id: String = ""                    # 스킬 고유 ID
var display: Display                   # 표시 정보
var requirements: Requirements         # 요구 조건 정보
var execution: Execution               # 실행 정보

static func from_dict(skill_id: String, dict: Dictionary) -> SkillData:
	var skill = SkillData.new()
	skill.id = skill_id
	skill.display = Display.from_dict(dict.get("display", {}))
	skill.requirements = Requirements.from_dict(dict.get("requirements", {}))
	skill.execution = Execution.from_dict(dict.get("execution", {}))
	return skill

## 기존 딕셔너리 기반 로직과의 호환성을 위한 변환 함수
func to_dict() -> Dictionary:
	return {
		"id": id,
		"display": {
			"name": display.name,
			"description": display.description,
			"owner_type": display.owner_type,
			"icon": display.icon
		},
		"requirement": { 
			"cost": requirements.cost,
			"condition": requirements.conditions.map(func(c): return {
				"stat": c.stat,
				"op": c.op,
				"value": c.value
			}),
			"cooldown": requirements.cooldown
		},
		"execution": {
			"target": execution.target,
			"actions": execution.actions.map(func(a): return {
				"type": a.type,
				"formula": {
					"base": a.formula.base,
					"scaling_stat": a.formula.scaling_stat,
					"multiplier": a.formula.multiplier
				},
				"element": a.element,
				"effect_id": a.effect_id,
				"chance": a.chance
			}),
			"element": execution.element
		}
	}
