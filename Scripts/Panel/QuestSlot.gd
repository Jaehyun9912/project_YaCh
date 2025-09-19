extends InventorySlot
class_name QuestSlot


func update_slot():
	nameText.text = data["title"]
	

func get_title():
	return data["title"]

func get_description():
	return data["description"]

func read():
	pass