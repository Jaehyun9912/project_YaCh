extends InventorySlot
class_name ItemSlot

var item_data: ItemData:
	get: return data.item if data else null

# 아이템 데이터 세팅
func set_slot(_slot_obj):
	data = _slot_obj
	countText.show()
	update_slot()

# 아이템 개수 변동 시 정보 갱신
func update_slot():
	if item_data:
		nameText.text = item_data.display.name
		if data.count > 0:
			countText.text = "x" + str(data.count)
		else:
			self.queue_free()
	else:
		self.queue_free()

func get_title():
	return item_data.display.name if item_data else ""

func get_description():
	if item_data:
		if item_data.logic.effects.size() > 0:
			return item_data.display.description.format(item_data.logic.effects[0].to_dict())
		else:
			return item_data.display.description
	else:
		return ""

func get_slot_method_list(condition: Dictionary) -> Array:
	var arr = ["discard"]
	if item_data == null:
		return arr
	
	# 카테고리가 useable이거나, 효과(effects)가 정의되어 있는 경우 사용 가능으로 판단
	var can_use = (item_data.display.category == "useable") or (item_data.logic.effects.size() > 0)
	
	if not can_use:
		return arr

	var is_battle = condition.get("isBattle", false)
	
	# battle_only 체크
	if item_data.logic.battle_only:
		if is_battle:
			arr.insert(0, "use")
	else:
		arr.insert(0, "use")
		
	return arr

func use():
	print("아이템 사용")
	discard()


func discard():
	if item_data:
		PlayerData.add_new_item(item_data.id, -1)