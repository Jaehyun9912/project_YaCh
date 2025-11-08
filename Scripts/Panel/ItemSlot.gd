extends InventorySlot
class_name ItemSlot

var item_data

func set_slot(_data):
	data = _data
	item_data = DataManager.get_item_data(data["id"])
	countText.show()
	update_slot()

	
func update_slot():
	nameText.text = item_data["name"]
	if data.has("count"):
		countText.text = "x" + str(data["count"])
		if data["count"] == 0:
			self.queue_free()
	else:
		countText.hide()

func get_title():
	return item_data["name"]

func get_description():
	return item_data["description"]

func get_slot_method_list(condition: Dictionary) -> Array:
	var arr = ["discard"]
	if (condition["isBattle"] == true) == (item_data["category"] == "battle"):
		arr.insert(0, "use")
	return arr

func use():
	print("아이템 사용")
	discard()


func discard():
	if data.has("count"):
		data["count"] -= 1
		if data["count"] == 0:
			queue_free()
			return
	else:
		queue_free()