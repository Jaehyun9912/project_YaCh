## [AttributeData] 전투 속성 정보를 담는 데이터 클래스입니다.
class_name AttributeData
extends RefCounted

## UI 표시용 정보 클래스
class Display:
	var name: String = ""              # 속성 이름
	var color: int = 4294967295        # RGBA 색상 값

	static func from_dict(dict: Dictionary) -> Display:
		var d = Display.new()
		d.name = dict.get("name", "")
		d.color = dict.get("color", 4294967295)
		return d

## 임계점(Overdrive) 도달 시의 로직 클래스
class Overdrive:
	## 오버드라이브 시 발생하는 개별 효과 클래스
	class Effect:
		var description: String = ""   # 효과 설명
		var target: String = "hp"      # 대상
		var apply_type: String = "once" # 타이밍 (once, tick, constant)
		var value_type: String = "add" # 연산 방식
		var value: float = 0.0         # 수치
		var restore: bool = false      # 종료 후 복구 여부

		static func from_dict(dict: Dictionary) -> Effect:
			var e = Effect.new()
			e.description = dict.get("description", "")
			e.target = dict.get("target", "hp")
			e.apply_type = dict.get("apply_type", "once")
			e.value_type = dict.get("value_type", "add")
			e.value = dict.get("value", 0.0)
			e.restore = dict.get("restore", false)
			return e

	var type: String = "EXPLODE"       # 타입 (EXPLODE: 즉시 발동 후 소멸, KEEP: 유지)
	var threshold: float = 0.8         # 발동 임계점 (0~1)
	var threshold_end: float = 0.6     # 종료 임계점 (KEEP 타입 전용)
	var effects: Array[Effect] = []    # 발생할 효과 리스트

	static func from_dict(dict: Dictionary) -> Overdrive:
		var o = Overdrive.new()
		o.type = dict.get("type", "EXPLODE")
		o.threshold = dict.get("threshold", 0.8)
		o.threshold_end = dict.get("threshold_end", 0.6)
		for e_dict in dict.get("effects", []):
			o.effects.append(Effect.from_dict(e_dict))
		return o

var id: String = ""                    # 속성 고유 ID (예: "fire", "ice")
var display: Display                   # 표시 정보
var overdrive: Overdrive               # 오버드라이브 설정 정보

static func from_dict(attr_id: String, dict: Dictionary) -> AttributeData:
	var attr = AttributeData.new()
	attr.id = attr_id
	attr.display = Display.from_dict(dict.get("display", {}))
	attr.overdrive = Overdrive.from_dict(dict.get("overdrive", {}))
	return attr
