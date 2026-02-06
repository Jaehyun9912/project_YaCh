class_name CharacterStat
extends RefCounted

signal stat_changed(stat_name, new_value)

var _target: Node
var _data: Dictionary
var armor_weight: float = 0

var buff_handler: BuffHandler
var _buff_cache: Dictionary = {}

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
    buff_handler.buff_changed.connect(_on_buff_changed)

    _init_stats()

func update_target(new_target: Node):
    _target = new_target

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

# 마나 최대치
func get_max_mana() -> float:
    var base_mana = _get_base_max_mana_logic()
    var buff_data = get_buff_stats("mana", base_mana)
    return buff_data

# 체력 최대치
func get_max_hp() -> float:
    var base_mana = _get_base_max_mana_logic()
    var buff_data = get_buff_stats("max_hp", base_mana * HP_SCALE_CONST)
    return buff_data

# 속도 계산
func get_speed() -> float:
    var level = get_skill_level()
    var permanent = _data.get("speed_bonus", 0)
    var armor_mult = max(armor_weight, 0.001)
    
    var base_speed = ((BASE_SPEED_DEFAULT + (level * LEVEL_SPEED_COEF)) * (1.0 / armor_mult)) + permanent
    var buff_data = get_buff_stats("speed", base_speed)
    return buff_data

# 들어오는 데미지 계산
func calculate_incoming_damage(raw_damage: float) -> float:
    var base_value = 1.0 - armor_weight
    var buff_data = get_buff_stats("damage_reduction", base_value)
    buff_data = 0 if buff_data < 0 else buff_data
    return raw_damage * buff_data

# 방어구 무게 설정
func set_armor_weight(new_armor_weight: float):
    armor_weight = new_armor_weight

# 속도 보너스 설정
func set_speed_bonus(amount: float):
    _data["speed_bonus"] = amount

# 마나 보너스 설정
func set_mana_bonus(amount: float):
    _data["mana_bonus"] = amount

# 기본 스탯 접근 함수
func get_stat(key, default=null): return _data.get(key, default)
func set_stat(key, val): _data[key] = val

# 실제 값 변경 적용 (Active Effect용)
func apply_value_change(stat_name: String, value: float):
    # 타겟이 있으면 타겟 메소드 우선 시도
    if not is_instance_valid(_target): return

    if stat_name == "hp":
        if _target.has_method("change_hp"):
            _target.change_hp(value)
        elif "hp" in _target: # Setter가 있다면
            _target.hp += value
    
    elif stat_name == "mana":
        if _target.has_method("change_mana"):
            _target.change_mana(value)
        elif "mana" in _target:
            _target.mana += value

func _on_buff_changed(buff: SkillBuff, _is_added: bool):
    var target_stat = buff.target
    
    var old_max_hp = 0.0
    if target_stat == "max_hp":
        old_max_hp = get_max_hp()

    # 캐시 재계산
    _recalculate_buff_cache(target_stat)
    
    # 해당 스탯의 현재 값을 다시 계산
    var current_val = get_stat(target_stat, 0)
    
    # getter가 있는 특수 스탯 처리
    if target_stat == "max_hp":
        current_val = get_max_hp()
        
        var hp_diff = current_val - old_max_hp
        if hp_diff > 0:
            apply_value_change("hp", hp_diff)
        elif hp_diff < 0:
            # 최대 체력이 감소한 경우 현재 체력이 새로운 최대치를 넘지 않도록 조정
            apply_value_change("hp", 0)
            
        print("Max HP changed: ", current_val)
    elif target_stat == "max_mana":
        current_val = get_max_mana()
    elif target_stat == "speed":
        current_val = get_speed()
    elif target_stat == "damage_reduction":
        current_val = calculate_incoming_damage(100) # 더미 값으로 비율 확인용

    print("Stat changed: ", target_stat, " New Value: ", current_val)
        
    stat_changed.emit(target_stat, current_val)

#endregion

#region BuffEvent
# buff_handler 관련 래퍼 함수
func add_buff(buff_id: String, duration_add: int = 0):
    buff_handler.add_buff(buff_id, duration_add)

func add_buff_object(buff: SkillBuff):
    buff_handler.add_buff_instance(buff)

func update_buffs(event: BuffHandler.BuffEvent):
    buff_handler.buff_update(event)

func remove_buffs_by_id(buff_id: String):
    buff_handler.remove_buffs_by_id(buff_id)

func _recalculate_buff_cache(stat_name: String):
    var buffs = buff_handler.get_buffs(stat_name)
    var m = 1.0
    var a = 0.0
    
    # 캐시 계산 전 디버깅 (버프가 있는데 적용 안되는 경우 확인용)
    if buffs.size() > 0:
        print("[StatCache] Recalculating for '%s' with %d buffs." % [stat_name, buffs.size()])
    
    match stat_name:
        "max_mana":
            # 마나는 버프 순서대로 연산 ((Base * m + a) + V or * V)
            for buff in buffs:
                if buff.is_additive():
                    a += buff.value
                else:
                    m *= buff.value
                    a *= buff.value
        "speed":
            # 속도는 곱셈 후 합 연산
            var mult_total = 1.0
            var add_total = 0.0
            for buff in buffs:
                if buff.is_additive():
                    add_total += buff.value
                else:
                    mult_total *= buff.value
            m = mult_total
            a = add_total
        _:
            # 나머지: 모두 더하기
            for buff in buffs:
                # 여기서 buff.value가 0인지, 혹은 합연산인지 확인
                # print(" - Processing Buff: %s Value: %s" % [buff.id, buff.value])
                a += buff.value
            m = 1.0

    _buff_cache[stat_name] = {"m": m, "a": a}

# 특정 스탯에 적용된 버프들을 계산하여 최종 값 반환
func get_buff_stats(target_stat: String, base_value: float):
    # 캐시에 없으면 계산
    if not _buff_cache.has(target_stat):
        _recalculate_buff_cache(target_stat)
    
    var cache = _buff_cache[target_stat]
    
    # 값이 이상할 경우 디버깅용
    # if cache.a == 0 and cache.m == 1.0:
    #     pass 
    
    return (base_value * cache.m) + cache.a 
#endregion