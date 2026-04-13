## [AttributeData] 전투 속성 정보를 담는 데이터 클래스입니다.
class_name AttributeData
extends RefCounted

## UI 표시용 정보 클래스
class Display:
	var name: String = ""              # 속성 이름
	var color: Color = Color.WHITE     # RGBA 색상 값

	static func from_dict(dict: Dictionary) -> Display:
		var d = Display.new()
		d.name = dict.get("name", "")

		var c_val = dict.get("color", 4294967295) # 기본값: 0xFFFFFFFF (흰색)
		d.color = Color.hex(c_val)
		return d

## 임계점(Overdrive) 도달 시의 로직 클래스
class Overdrive:
	enum OverdriveType {
		EXPLODE, # 즉시 발동 후 소멸
		KEEP     # 일정 수치 유지 동안 지속
	}

	var type: OverdriveType = OverdriveType.EXPLODE # 타입 (EXPLODE, KEEP)
	var threshold: float = 0.8         # 발동 임계점 (0~1)
	var threshold_end: float = 0.6     # 종료 임계점 (KEEP 타입 전용)
	var effects: Array[EffectData] = [] # 발생할 효과 리스트 (EffectData와 통합)

	static func from_dict(dict: Dictionary, attr_id: String) -> Overdrive:
		var o = Overdrive.new()
		var type_str = dict.get("type", "EXPLODE")
		if type_str == "KEEP":
			o.type = OverdriveType.KEEP
		else:
			o.type = OverdriveType.EXPLODE
			
		o.threshold = dict.get("threshold", 0.8)
		o.threshold_end = dict.get("threshold_end", 0.6)
		
		for e_dict in dict.get("effects", []):
			o.effects.append(EffectData.from_dict("attribute_" + attr_id, e_dict))
		return o

var id: String = ""                    # 속성 고유 ID (예: "fire", "ice")
var display: Display                   # 표시 정보
var overdrive: Overdrive               # 오버드라이브 설정 정보

static func from_dict(attr_id: String, dict: Dictionary) -> AttributeData:
	var attr = AttributeData.new()
	attr.id = attr_id
	attr.display = Display.from_dict(dict.get("display", {}))
	attr.overdrive = Overdrive.from_dict(dict.get("overdrive", {}), attr_id)
	return attr
