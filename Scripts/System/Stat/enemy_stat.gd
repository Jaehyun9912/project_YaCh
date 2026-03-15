class_name EnemyStat
extends CharacterStat

var max_hp = null

func get_max_hp() -> float:
    if max_hp != null:
        return get_buff_stats("max_hp", float(max_hp))
    return super.get_max_hp()

func setup(target: Node, data: Dictionary):
    super.setup(target, data)
    max_hp = data.get("hp", null)