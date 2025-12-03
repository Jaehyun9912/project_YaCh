extends Node3D
class_name BattleCharacter

signal character_died(char: BattleCharacter)

const hp_text_string := "HP : %d / %d"
@onready var _hp_label := $HpLabel
@onready var _notify_label := $NotifyLabel
@onready var _notify_timer := $NotifyLabel/Timer

# 스탯 관리용 딕셔너리
# 구조: "stat_name": { "base": 10, "add": 0, "mult": 1.0 }
var _stats: Dictionary = {}

var speed: float:
    get: return get_stat("speed")
var attack: float:
    get: return get_stat("attack")
var max_hp: float:
    get: return get_stat("max_hp")
var mana: float:
    get: return get_stat("mana")

var skills

var tag: String

var _hp
var hp:
    get:
        return _hp
    set(value):
        # max_hp는 이제 getter를 통해 계산된 값을 가져옴
        if value > max_hp:
            value = max_hp

        var diff = value - _hp
        _hp = value
        _hp_label.text = hp_text_string % [hp, max_hp]
        
        if hp <= 0:
            _died()
        elif diff > 0:
            notify_msg(diff, Color.GREEN)
        else:
            notify_msg(diff, Color.RED)
            
        if is_player:
            PlayerData.hp = _hp;
            
# 행동력 
var point: int
var current_point: int

# 플레이어인지 확인용 
@export var is_player := false

var init_outline_size
var init_outline_color
var tag_service

func _ready():
    init_outline_size = _hp_label.outline_size
    init_outline_color = _hp_label.outline_modulate
    tag_service = DiContainer.get_tag_service()

# 스탯 초기화 함수
func init_stat(stat_name: String, value: float):
    _stats[stat_name] = {
        "base": value,
        "add": 0.0,
        "mult": 1.0
    }

# 스탯 계산 함수 (Base + Add) * Mult
func get_stat(stat_name: String) -> float:
    if not _stats.has(stat_name):
        return 0.0
    
    var s = _stats[stat_name]
    return (s["base"] + s["add"]) * s["mult"]

# 스탯 수정 함수
func modify_stat(stat_name: String, oper: String, value: float):
    # 체력만 별도 처리
    if stat_name == "hp":
        match oper:
            "add":
                hp += value
            "remove":
                hp -= value
            "multiply":
                hp = int(hp * value)
            "divide":
                if value != 0:
                    hp = int(hp / value)
        _hp_label.text = hp_text_string % [hp, max_hp]
        return

    if not _stats.has(stat_name):
        printerr("Stat not found: ", stat_name)
        return

    match oper:
        "add":
            _stats[stat_name]["add"] += value
        "remove":
            _stats[stat_name]["add"] -= value
        "multiply":
            _stats[stat_name]["mult"] *= value
        "divide":
            if value != 0:
                _stats[stat_name]["mult"] /= value

    if stat_name == "max_hp":
        _hp_label.text = hp_text_string % [hp, max_hp]

# 죽었을 때 
func _died():
    character_died.emit(self)
    
    if tag_service.has_method("change_tag_tree"):
        tag_service.change_tag_tree(self, tag, 0)
    
# 캐릭터 위에 메세지 띄우기 
func notify_msg(msg, color):
    _notify_label.text = str(msg)
    _notify_label.modulate = color
    _notify_label.visible = true
    _notify_timer.start()
    
    # 잠시후 종료 
    await _notify_timer.timeout
    
    _notify_label.visible = false
	
# 캐릭터 정보 설정 
func set_character(data: Dictionary, tag_id: String):
    #name = data.name
    
    # 스탯 초기화 방식으로 변경
    init_stat("attack", data.get("attack", 0))
    init_stat("max_hp", data.get("max_hp", data.hp))
    init_stat("speed", data.speed)
    init_stat("mana", data.mana)
    
    _hp = data.hp
    _hp_label.text = hp_text_string % [hp, max_hp]
    
    skills = data.skills
    
    # 태그 추가하기 
    tag = "Battle." + tag_id
    if tag_service.has_method("change_tag_tree"):
        tag_service.change_tag_tree(self, tag, 1)
    #print(data)
    
# 캐릭터의 체력 텍스트 외곽선 설정 
func set_hp_outline(size: int, color: Color):
    _hp_label.outline_size = size
    _hp_label.outline_modulate = color

# 미리 설정된 프리셋 
func set_hp_outline_default(): set_hp_outline(init_outline_size, init_outline_color)
func set_hp_outline_red(): set_hp_outline(30, Color.RED)
func set_hp_outline_green(): set_hp_outline(30, Color.GREEN)

# 적이면 빨간색, 아군이면 초록색으로 설정
func set_hp_outline_target():
    if is_player: set_hp_outline_green()
    else: set_hp_outline_red()
