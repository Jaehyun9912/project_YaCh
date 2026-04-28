extends Node

var items: Dictionary

func _ready():
    items = DataManager.load_datas_dict("Item", ItemData)

func get_item(id: String) -> ItemData:
    if id in items:
        return items[id]
    printerr("[ItemManager] 잘못된 아이템 ID! : ", id)
    return null
