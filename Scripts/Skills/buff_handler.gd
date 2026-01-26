class_name BuffHandler extends RefCounted

class BuffEvent:
    enum Type { TURN, TIME_PASS, ACTION_POINT, LOCATION_CHANGE, ATTRIBUTE_CHANGE }
    var type: Type
    var value
    var attribute: String = ""

var active_buffs: Array[SkillBuff] = []
var _target_ref: WeakRef # RefCounted간 순환 참조 방지용

# 실제 사용 시 get_ref()를 통해 접근하는 프로퍼티
var target: CharacterStat:
    get:
        return _target_ref.get_ref() if _target_ref else null

func setup(set_target: CharacterStat):
    _target_ref = weakref(set_target)

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
    if not target: # CharacterStat이 이미 지워졌다면 중단
        return
        
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