class_name BuffHandler extends Node

class BuffEvent:
    enum Type { TURN, TIME_PASS, ACTION_POINT, LOCATION_CHANGE, ATTRIBUTE_CHANGE }
    var type: Type
    var value
    var attribute: String = ""

var active_buffs: Array[SkillBuff] = []
var target: WeakRef # player_stat, battle_character 등 버프를 적용할 대상

func setup(set_target):
    self.target = set_target

func add_buff(buff_id: String):
    var buff = SkillManager.get_buff(buff_id)
    active_buffs.append(buff)
    print("Buff added: ", buff.id)

func get_buffs(target_stat: String) -> Array[SkillBuff]:
    # 특정 스탯에 적용되는 버프들 반환
    var result: Array[SkillBuff] = []
    for buff in active_buffs:
        if target_stat in buff.target:
            result.append(buff)
    return result

func buff_update(event: BuffEvent):
    var expired_buffs: Array[SkillBuff] = []
    for buff in active_buffs:
        if buff.check_update_logic(event):
            expired_buffs.append(buff)

    for buff in expired_buffs:
        remove_buff(buff)
        print("BuffHandler: Buff expired: ", buff.id)

func remove_buff(buff: SkillBuff):
    active_buffs.erase(buff)
    if buff.next_buff != "":
        add_buff(buff.next_buff)

func clear_battle_buffs():
    # 전투 관련 버프만 제거
    var to_remove: Array[SkillBuff] = []
    for buff in active_buffs:
        if buff.is_battle_buff():
            to_remove.append(buff)
    
    for buff in to_remove:
        remove_buff(buff)