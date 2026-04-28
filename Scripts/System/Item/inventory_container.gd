class_name InventoryContainer
extends RefCounted

# 아이템 변경 시 알림 (아이템ID, 변경 후 총 개수)
signal item_changed(id: String, total_count: int)

## 모든 아이템 정보를 저장하는 딕셔너리 (아이템 ID: 개수)
var items: Dictionary = {}

## 아이템 일괄 설정
func set_all_item(data: Dictionary):
	items.clear()
	var items_data = data.get("items", [])
	for item_info in items_data:
		var item_id = item_info.get("item", "")
		var count = item_info.get("count", 0)
		if ItemManager.get_item(item_id): # 존재하는 아이템인지 확인
			items[item_id] = count

## 현재 인벤토리 상태를 딕셔너리로 반환
func get_inventory_contents() -> Array:
	var items_list = []
	for id in items:
		items_list.append({
			"item": id,
			"count": items[id]
		})
	return items_list

## UI 표시를 위해 { "item": ItemData, "count": int } 형태의 배열 반환
func get_entries() -> Array:
	var result = []
	for id in items:
		var item_data = ItemManager.get_item(id)
		if item_data:
			result.append({
				"item": item_data,
				"count": items[id]
			})
	return result

## 아이템 추가/제거 통합 관리
func add_item(id: String, count: int):
	if count > 0:
		_add_item(id, count)
	elif count < 0:
		_remove_item(id, abs(count))

func _add_item(id: String, count: int):
	if not ItemManager.get_item(id): return
	
	items[id] = items.get(id, 0) + count
	item_changed.emit(id, items[id])

func _remove_item(id: String, count: int) -> bool:
	if not items.has(id) or items[id] < count:
		printerr("[InventoryContainer] 아이템 부족: ", id)
		return false
	
	items[id] -= count
	if items[id] <= 0:
		items.erase(id)
	
	item_changed.emit(id, items.get(id, 0))
	return true

func is_item(id: String) -> bool:
	return items.has(id) and items[id] > 0

func get_item_count(id: String) -> int:
	return items.get(id, 0)
