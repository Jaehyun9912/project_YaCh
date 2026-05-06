class_name PlayerStat
extends CharacterStat

func setup(player: Node, data: Dictionary):
    super.setup(player, data) # 부모의 setup 호출 (_target, _data 설정 및 초기화)

# 숙련도 추가
func add_skill_exp(amount: float, mana_consumed: float = 0, is_combat: bool = false):
    var final_add = amount
    if is_combat:
        var level = get_skill_level()
        final_add += (level * mana_consumed)
    
    _data["skill_exp"] = _data.get("skill_exp", 0) + final_add
    print("Exp Added: ", final_add, " Total: ", _data["skill_exp"])

## 영구 마나 획득
func add_permanent_mana(amount: float):
    set_mana_bonus(get_stat("mana_bonus", 0) + amount)

## 영구 속도 획득
func add_permanent_speed(amount: float):
    set_speed_bonus(get_stat("speed_bonus", 0) + amount)

## 인벤토리 변경시 장비 스탯 업데이트
func update_equipment_stats(new_armor_weight: float):
    # TODO: (나중에 처리 필요)
    set_armor_weight(new_armor_weight)

