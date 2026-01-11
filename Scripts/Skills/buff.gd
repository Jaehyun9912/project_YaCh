extends Resource
class_name SkillBuff

enum ApplyType { ONCE, EVERY, END }
enum DurationType { TIME, TURN, POINT, ATTR_UNDER, ATTR_UPPER }

@export_group("Basic Info")
@export var id: String
@export var target: Array = [] # [string]
@export var value_type: String = "add" # "add", "multiplier"
@export var value: float = 0.0

@export_group("Logic")
@export var apply_type: ApplyType = ApplyType.ONCE
@export var restore: bool = false
@export var next_buff: String = ""

@export_group("Duration & Condition")
@export var has_duration: bool = false  # 지속시간이 있는지 여부
@export var duration_type: DurationType # 지속시간 타입
@export var duration_value: float = 0.0 # 지속시간 값
@export var duration_attr: String = "" # attribute 계열용
@export var location_condition: String = "" # 특정 지역/시간 ID

# JSON 데이터로부터 인스턴스 생성
static func create_from_dict(orig_id: String, data: Dictionary) -> SkillBuff:
    var b = SkillBuff.new()
    b.id = orig_id
    
    # Target이 문자열이면 배열로 변환
    var t = data.get("target", "")
    b.target = t if t is Array else [t]
    
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
    
    return b

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

func is_battle_buff() -> bool:
    if duration_type in [DurationType.TURN, DurationType.POINT, DurationType.ATTR_UNDER, DurationType.ATTR_UPPER]:
        return true
    return false