class_name CharacterStat
extends RefCounted

var _target: Node
var _data: Dictionary
var armor_weight: float = 0

var buff_handler: BuffHandler

# 공식 계산용 함수 
const BASE_MANA_DEFAULT = 100
const LEVEL_MANA_COEF = 50
const BASE_SPEED_DEFAULT = 10
const LEVEL_SPEED_COEF = 2
const HP_SCALE_CONST = 1.0

func setup(target: Node, data: Dictionary):
    _target = target
    _data = data

    buff_handler = BuffHandler.new()
    buff_handler.setup(self)

    _init_stats()

#region Stat

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
    var base_mana = _get_base_max_mana_logic()
    var buff_data = get_buff_stats("mana", base_mana)
    return buff_data

func get_max_hp() -> float:
    var base_mana = _get_base_max_mana_logic()
    var buff_data = get_buff_stats("max_hp", base_mana * HP_SCALE_CONST)
    return buff_data

func get_speed() -> float:
    var level = get_skill_level()
    var permanent = _data.get("speed_bonus", 0)
    var armor_mult = max(armor_weight, 0.001)
    
    var base_speed = ((BASE_SPEED_DEFAULT + (level * LEVEL_SPEED_COEF)) * (1.0 / armor_mult)) + permanent
    var buff_data = get_buff_stats("speed", base_speed)
    return buff_data

func calculate_incoming_damage(raw_damage: float) -> float:
    var base_value = 1.0 - armor_weight
    var buff_data = get_buff_stats("damage_reduction", base_value)
    buff_data = 0 if buff_data < 0 else buff_data
    return raw_damage * buff_data

func set_armor_weight(new_armor_weight: float):
    armor_weight = new_armor_weight

func set_speed_bonus(amount: float):
    _data["speed_bonus"] = amount

func set_mana_bonus(amount: float):
    _data["mana_bonus"] = amount

func get_stat(key, default=null): return _data.get(key, default)
func set_stat(key, val): _data[key] = val
#endregion

#region BuffEvent
func add_buff(buff_id: String):
    buff_handler.add_buff(buff_id)

func buff_update(event: BuffHandler.BuffEvent):
    buff_handler.buff_update(event)

func get_buff_stats(target_stat: String, base_value: float):
    var buffs = buff_handler.get_buffs(target_stat) as Array[SkillBuff]
    var result = base_value
    
    match target_stat:
        "mana":
            # 마나는 버프 순서대로 연산
            for buff in buffs:
                if buff.is_additive():
                    result += buff.value
                else:
                    result *= buff.value
        "speed":
            # 속도는 곱셈 후 합 연산
            var mult_total = 1.0
            var add_total = 0.0
            for buff in buffs:
                if buff.is_additive():
                    add_total += buff.value
                else:
                    mult_total *= buff.value
            result = (result * mult_total) + add_total
        _:
            # 나머지: 모두 더하기 (곱연산이 없음)
            for buff in buffs:
                result += buff.value

    return result
    
#endregion