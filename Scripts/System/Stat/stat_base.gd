class_name CharacterStat
extends Node

var _target: Node
var _data: Dictionary
var armor_weight: float = 0.1

# 공식 계산용 함수 
const BASE_MANA_DEFAULT = 100
const LEVEL_MANA_COEF = 50
const BASE_SPEED_DEFAULT = 10
const LEVEL_SPEED_COEF = 2
const HP_SCALE_CONST = 10.0

func setup(target: Node, data: Dictionary):
    _target = target
    _data = data
    _init_stats()

func _init_stats():
    if not _data.has("mana_bonus"): _data["mana_bonus"] = 0
    if not _data.has("speed_bonus"): _data["speed_bonus"] = 0

# 공통 레벨/숙련도 계산 (적의 경우 data에 고정값을 넣거나 별도 로직 적용)
func get_skill_level() -> int:
    var exp_amount = _data.get("skill_exp", 0)
    if exp_amount <= 0: return 0
    return int(sqrt(exp_amount / 100.0))

func _get_base_max_mana_logic() -> float:
    var level = get_skill_level()
    var permanent = _data.get("mana_bonus", 0)
    return (BASE_MANA_DEFAULT + (level * LEVEL_MANA_COEF)) + permanent

func get_max_mana() -> float:
    return _get_base_max_mana_logic()

func get_max_hp() -> float:
    return _get_base_max_mana_logic() * HP_SCALE_CONST

func get_speed() -> float:
    var level = get_skill_level()
    var permanent = _data.get("speed_bonus", 0)
    var armor_mult = max(armor_weight, 0.001)
    return ((BASE_SPEED_DEFAULT + (level * LEVEL_SPEED_COEF)) * (1.0 / armor_mult)) + permanent

func calculate_incoming_damage(raw_damage: float) -> float:
    return raw_damage * (1.0 - armor_weight)

func set_armor_weight(new_armor_weight: float):
    armor_weight = new_armor_weight

func set_speed_bonus(amount: float):
    _data["speed_bonus"] = amount

func set_mana_bonus(amount: float):
    _data["mana_bonus"] = amount

func get_stat(key, default=null): return _data.get(key, default)
func set_stat(key, val): _data[key] = val