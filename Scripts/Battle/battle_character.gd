extends Node3D
class_name BattleCharacter

signal character_died(char: BattleCharacter)

const hp_text_string := "HP : %d / %d"
@onready var _hp_label := $HpLabel
@onready var _notify_label := $NotifyLabel
@onready var _notify_timer := $NotifyLabel/Timer

# 스탯 관리자
var stat_manager: CharacterStat

var speed: float:
    get: return stat_manager.get_speed()
var attack: float:
    get: return stat_manager.get_stat("attack", 0.0)
var max_hp: float:
    get: return stat_manager.get_max_hp()
var mana: float:
    get: return stat_manager.get_stat("mana", 0.0) # 현재 마나 (세션값)
var max_mana: float:
    get: return stat_manager.get_max_mana()

var skills
var tag: String

var _hp: float
var hp:
    get:
        return _hp
    set(value): # apply_damage, apply_heal 함수로 처리하므로 refresh는 수행하지 않음 (따라서 직접 설정은 자제)
        # var diff = value - _hp
        _hp = value
        # _refresh_hp_status(diff)
            

# 행동력 
var point: int
var current_point: int

# 플레이어인지 확인용 
@export var is_player := false
var tag_service

func _ready():
    tag_service = DiContainer.get_tag_service()
    # 플레이어라면 PlayerData에 이미 생성된 stat_manager가 있을 것이므로 
    # set_character에서 연결만 해줌.

# 캐릭터 정보 설정 
func set_character(data: Dictionary, tag_id: String):
    if is_player:
        # 플레이어는 PlayerData에 있는 stat_manager를 그대로 참조
        stat_manager = PlayerData.stat_manager
    else:
        # 적은 새로운 Stat 매니저 생성 및 데이터 주입
        stat_manager = EnemyStat.new()
        stat_manager.setup(self, data)
    
    # 초기 HP 설정 (데이터에 없으면 max_hp로 설정)
    _hp = data.get("hp", max_hp)
    _hp_label.text = hp_text_string % [int(_hp), int(max_hp)]
    
    skills = data.get("skills", [])
    tag = "Battle." + tag_id
    if tag_service.has_method("change_tag_tree"):
        tag_service.change_tag_tree(self, tag, 1)

# 내부 공용 UI 업데이트 함수
func _refresh_hp_status(diff: float):
    _hp_label.text = hp_text_string % [int(_hp), int(max_hp)]
    
    if _hp <= 0:
        _died()
    elif diff != 0:
        var color = Color.GREEN if diff > 0 else Color.RED
        notify_msg(int(abs(diff)), color)

func apply_damage(amount: float) -> float:
    var damage = stat_manager.calculate_incoming_damage(amount)
    _hp = max(_hp - damage, 0)
    _refresh_hp_status(-damage)
    return damage

func apply_heal(amount: float) -> float:
    var old_hp = _hp
    _hp = min(_hp + amount, max_hp)
    var actual_heal = _hp - old_hp
    _refresh_hp_status(actual_heal)
    return actual_heal

# 죽었을 때 
func _died():
    character_died.emit(self)
    
    if tag_service.has_method("change_tag_tree"):
        tag_service.change_tag_tree(self, tag, 0)
    
# 캐릭터 위에 메세지 띄우기 
func notify_msg(msg, color):
    _notify_label.text = str(msg)
    _notify_label.modulate = color
    
    _notify_timer.stop()
    _notify_label.visible = true
    _notify_timer.start()
    
    # 잠시후 종료 
    await _notify_timer.timeout
    
    _notify_label.visible = false

# 캐릭터의 체력 텍스트 외곽선 설정 
func set_hp_outline(size: int, color: Color):
    _hp_label.outline_size = size
    _hp_label.outline_modulate = color

# 미리 설정된 프리셋 
func set_hp_outline_default(): set_hp_outline(30, Color.BLACK)
func set_hp_outline_red(): set_hp_outline(30, Color.RED)
func set_hp_outline_green(): set_hp_outline(30, Color.GREEN)

# 적이면 빨간색, 아군이면 초록색으로 설정
func set_hp_outline_target():
    if is_player: set_hp_outline_green()
    else: set_hp_outline_red()
