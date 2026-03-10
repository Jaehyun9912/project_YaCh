extends Resource
class_name SkillBuff

enum ApplyType { ONCE, EVERY, END }
enum DurationType { NONE, TIME, TURN, POINT, ATTR_UNDER, ATTR_UPPER }

@export var id: String
@export var target: String = "" # 버프를 적용할 대상 속성 이름
@export var value_type: String = "add" # "add", "multiplier"
@export var value: float = 0.0

@export var apply_type: ApplyType = ApplyType.ONCE
@export var restore: bool = false
@export var next_buff: String = ""

@export var has_duration: bool = false  # 지속시간이 있는지 여부
@export var duration_type: DurationType = DurationType.NONE # 지속시간 타입
@export var duration_value: float = 0.0 # 지속시간 값
@export var duration_attr: String = "" # attribute 계열용
@export var location_condition: String = "" # 특정 지역/시간 ID

var is_battle_buff: bool = false

# JSON 데이터로부터 인스턴스 생성
static func create_from_dict(orig_id: String, data: Dictionary) -> SkillBuff:
    var b = SkillBuff.new()
    b.id = orig_id
    
    b.target = data.get("target", "")
    if b.target == "":
        push_error("SkillBuff " + orig_id + " has no target specified.")
        return null
    b.value_type = data.get("value_type", "add")
    b.value = data.get("value", 0.0)
    b.restore = data.get("restore", false)
    b.next_buff = data.get("next_buff", "")
    
    # apply_type 변환
    var a_str = data.get("apply_type", "once").to_lower()
    b.apply_type = {"once": ApplyType.ONCE, "every": ApplyType.EVERY, "end": ApplyType.END}[a_str]
    
    # duration 처리
    if data.has("duration"):
        b.has_duration = true
        var d = data["duration"]
        var d_str = d.get("type", "turn").to_lower()
        b.duration_type = {
            "time": DurationType.TIME, "turn": DurationType.TURN, 
            "point": DurationType.POINT, "attribute_under": DurationType.ATTR_UNDER, 
            "attribute_upper": DurationType.ATTR_UPPER
        }[d_str]
        b.duration_value = d.get("value", 0.0)
        b.duration_attr = d.get("attribute", "")
        
    b.location_condition = data.get("location", "")
    b.is_battle_buff = b.duration_type in [DurationType.TURN, DurationType.POINT, DurationType.ATTR_UNDER, DurationType.ATTR_UPPER]
    
    return b

func is_additive() -> bool:
    return value_type == "add"

# 현재 이벤트가 지속시간 소모/발동 조건에 부합하는지 확인
func is_tick_event(event: BuffHandler.BuffEvent) -> bool:
    if not has_duration: return false
    
    match duration_type:
        DurationType.TIME:
            return event.type == BuffHandler.BuffEvent.Type.TIME_PASS
        DurationType.TURN:
            return event.type == BuffHandler.BuffEvent.Type.TURN
        DurationType.POINT:
            return event.type == BuffHandler.BuffEvent.Type.ACTION_POINT
        DurationType.ATTR_UNDER:
            return event.type == BuffHandler.BuffEvent.Type.ATTRIBUTE_CHANGE and event.attribute == duration_attr
        DurationType.ATTR_UPPER:
            return event.type == BuffHandler.BuffEvent.Type.ATTRIBUTE_CHANGE and event.attribute == duration_attr
    return false

func check_update_logic(event: BuffHandler.BuffEvent) -> bool:
    if not has_duration:
        return false
    
    match duration_type:
        DurationType.TIME:
            if event.type == BuffHandler.BuffEvent.Type.TIME_PASS:
                duration_value -= event.value
        DurationType.TURN:
            if event.type == BuffHandler.BuffEvent.Type.TURN:
                duration_value -= event.value
        DurationType.POINT:
            if event.type == BuffHandler.BuffEvent.Type.ACTION_POINT:
                duration_value -= event.value
        DurationType.ATTR_UNDER:
            if event.type == BuffHandler.BuffEvent.Type.ATTRIBUTE_CHANGE and event.attribute == duration_attr:
                if event.value < duration_value:
                    return true
        DurationType.ATTR_UPPER:
            if event.type == BuffHandler.BuffEvent.Type.ATTRIBUTE_CHANGE and event.attribute == duration_attr:
                if event.value > duration_value:
                    return true

    return duration_value <= 0.0

func is_location_valid(current_location: String) -> bool:
    if location_condition == "":
        return true
    return location_condition == current_location