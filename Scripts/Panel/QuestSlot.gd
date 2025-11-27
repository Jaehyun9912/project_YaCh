extends InventorySlot
class_name QuestSlot

var tag_manager: TagManager

func _init():
	tag_manager = TagService

func update_slot():
	nameText.text = data["title"]
	

func get_title():
	return data["title"]

func get_description():
	return data["description"]

func get_slot_method_list(condition: Dictionary) -> Array:
	return ["read"]

func read():
	print("퀘스트 오픈")
	if data.has("process_condition"):
		var dict = data["process_condition"]
		for i in dict:
			print(dict[i], " : ", Condition.check_condition(i))
		pass
