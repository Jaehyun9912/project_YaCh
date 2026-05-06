extends InventorySlot
class_name ArtifactSlot

var item_data: ItemData:
	get: return data.item if data else null

# 인벤토리의 아티펙트 슬롯 설정
func set_slot(_slot_obj):
	data = _slot_obj
	countText.hide()
	update_slot()
		
# 슬롯 업데이트
func update_slot():
	if item_data:
		nameText.text = item_data.display.name

func get_title():
	return item_data.display.name if item_data else ""

func get_description():
	return item_data.display.category if item_data else ""