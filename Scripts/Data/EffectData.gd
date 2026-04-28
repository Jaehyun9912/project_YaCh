## [EffectData] 버프, 디버프 등 모든 효과 정보를 담는 데이터 클래스입니다.
class_name EffectData
extends RefCounted

## 효과 지속 조건 설정 클래스
class Duration:
	var type: String = "turn"          # 종료 기준 (time, turn, point, attribute_under/upper)
	var value: float = 1               # 기준 수치
	var attribute: String = ""         # 체크할 대상 속성 ID (특정 타입 전용)
	var skip_first_tick: bool = false  # 부여 시점 틱 건너뜀 여부

	static func from_dict(dict: Dictionary) -> Duration:
		var d = Duration.new()
		d.type = dict.get("type", "turn")
		d.value = dict.get("value", 1)
		d.attribute = dict.get("attribute", "")
		d.skip_first_tick = dict.get("skip_first_tick", false)
		return d

var id: String = ""                    # 효과 고유 ID
var target: String = "attack"          # 적용 대상 능력치
var value_type: String = "add"         # 연산 방식 (add, multiplier)
var value: float = 0.0                 # 수치 (음수는 디버프)
var priority: int = 0                  # 우선순위
var apply_type: String = "once"        # 타이밍 (once, every, end)
var restore: bool = false              # 만료 시 수치 복구 여부
var next_buff: String = ""             # 만료 후 자동 발동 효과 ID
var duration: Duration                 # 지속 조건 설정

static func from_dict(effect_id, dict: Dictionary) -> EffectData:
	var effect = EffectData.new()
	effect.id = effect_id if effect_id is String and effect_id != "" else dict.get("id", "")
	effect.target = dict.get("target", "attack")
	effect.value_type = dict.get("value_type", "add")
	effect.value = dict.get("value", 0.0)
	effect.priority = dict.get("priority", 0)
	effect.apply_type = dict.get("apply_type", "once")
	effect.restore = dict.get("restore", false)
	effect.next_buff = dict.get("next_buff", "")
	effect.duration = Duration.from_dict(dict.get("duration", {}))
	return effect

func to_dict() -> Dictionary:
	return {
		"id": id,
		"target": target,
		"value_type": value_type,
		"value": value,
		"priority": priority,
		"apply_type": apply_type,
		"restore": restore,
		"next_buff": next_buff,
		"duration": {
			"type": duration.type,
			"value": duration.value,
			"attribute": duration.attribute,
			"skip_first_tick": duration.skip_first_tick
		}
	}