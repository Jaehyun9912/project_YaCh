class_name PlayerStat
extends Node

var _player: Node
var _data: Dictionary

var armor_weight: float = 0.1 # 장착한 방어구의 배율

# 상수 정의
const BASE_MANA_DEFAULT = 100
const LEVEL_MANA_COEF = 50
const BASE_SPEED_DEFAULT = 10
const LEVEL_SPEED_COEF = 2
const HP_SCALE_CONST = 10.0 # 예시: 마나 1당 체력 10

func setup(player: Node, data: Dictionary):
    _player = player
    _data = data
    # 데이터 초기화 보장
    if not _data.has("skill_exp"): _data["skill_exp"] = 0
    if not _data.has("mana_bonus"): _data["mana_bonus"] = 0 # 영구 획득량
    if not _data.has("speed_bonus"): _data["speed_bonus"] = 0 # 영구 획득량

#region 숙련도 및 레벨
# 숙련도 레벨 계산 (Data -> Calc)
func get_skill_level() -> int:
    var exp_amount = _data.get("skill_exp", 0)
    # 레벨 제곱 * 100 = 숙련도
    # 레벨 = sqrt(exp / 100)
    if exp_amount <= 0: return 0
    return int(sqrt(exp_amount / 100.0))

# 숙련도 추가
func add_skill_exp(amount: float, mana_consumed: float = 0, is_combat: bool = false):
    var final_add = amount
    if is_combat:
        var level = get_skill_level()
        # 전투 레벨(level) * 소모 마나
        final_add += (level * mana_consumed)
    
    # * 버프 배율 적용이 필요하다면 여기서 _modifiers 확인
    
    _data["skill_exp"] = _data.get("skill_exp", 0) + final_add
    print("Exp Added: ", final_add, " Total: ", _data["skill_exp"])
#endregion

#region 마나 최대치
# 기초 마나 최대치 (기본 + 레벨 + 영구획득)
func _get_base_max_mana_logic() -> float:
    var level = get_skill_level()
    var permanent = _data.get("mana_bonus", 0)
    return (BASE_MANA_DEFAULT + (level * LEVEL_MANA_COEF)) + permanent

# 최종 마나 최대치 (기초 + 버프)
func get_max_mana() -> float:
    var base = _get_base_max_mana_logic()
    # TODO 버프 로직: 기초 값 기준 +-x (연산은 버프 적용 순서대로)
    return base

# 영구 마나 획득 (기타 획득량)
func add_permanent_mana(amount: float):
    _data["mana_bonus"] = _data.get("mana_bonus", 0) + amount
#endregion

#region 체력 최대치
# 기초 최대치 : 기초 마나 최대치 * 상수
func get_max_hp() -> float:
    # * "마나 최대치는 현재 기준이 아닌 기초값 기준" -> _get_base_max_mana_logic 사용
    var base_mana = _get_base_max_mana_logic()
    var base_max_hp = base_mana * HP_SCALE_CONST
    
    # TODO 버프 로직: 기초 값 기준 +-

    return base_max_hp
#endregion

#region 속도
# 기초 값 : (기본 + 레벨) * (1/방어구) + 영구
func get_speed() -> float:
    var level = get_skill_level()
    var permanent = _data.get("speed_bonus", 0)

    # 높으면 느려지는 방어구 무게 배율
    var armor_mult = armor_weight
    if armor_mult == 0: armor_mult = 1.0 # 0 나누기 방지
    
    var base_speed = ((BASE_SPEED_DEFAULT + (level * LEVEL_SPEED_COEF)) * (1.0 / armor_mult)) + permanent
    
    # TODO 버프 로직: 기초 값 기준 +-x (곱셈 -> 합산 순)
    
    return base_speed
#endregion

#region 피해 감소
# 방어구 무게 배율 업데이트 (inventory 등에서 호출 필요)
func update_equipment_stats(new_armor_weight: float):
    # 방어구 무게 배율
    armor_weight = new_armor_weight

# 실제 데미지 계산 시 호출
func calculate_incoming_damage(raw_damage: float) -> float:
    var base_ratio = (1 - armor_weight)
    # armor_weight가 1이면 0% 데미지, 0이면 100% 데미지
    
    # TODO: 버프 로직: 기초 값 기준 +-

    # 들어온 데미지에 배율 곱
    return raw_damage * base_ratio

#endregion

# 기존 Getter/Setter (Data 직접 접근용)
func get_stat(key, default=null): return _data.get(key, default)
func set_stat(key, val): _data[key] = val
