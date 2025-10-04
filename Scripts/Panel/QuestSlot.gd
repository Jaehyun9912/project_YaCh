extends InventorySlot
class_name QuestSlot

var tag_manager: TagService

func _init():
	tag_manager = DiContainer.get_tag_service()

func update_slot():
	nameText.text = data["title"]
	

func get_title():
	return data["title"]

func get_description():
	return data["description"]

func read():
	print("퀘스트 오픈")
	if data.has("process_condition"):
		var dict = data["process_condition"]
		for i in dict:
			print(dict[i], " : ", check_condition(i))
		pass


func check_condition(condition) -> bool:
	# 반전 확인
	var negative = false
	if condition.begins_with("!"):
		condition = condition.right(-1)
		negative = true
	# 조건 분야 확인(태그, 아이템, 스탯)
	var arr = condition.split(":", true, 1)
	var check: bool
	if arr.size() == 1:
		check = tag_manager.tag_compare(PlayerData, arr[0])
	elif arr[0] == "tag":
		check = tag_manager.tag_compare(PlayerData, arr[1])
	elif arr[0] == "stat":
		check = PlayerData.stat_compare(arr[1])
	elif arr[0] == "item":
		check = PlayerData.item_compare(arr[1])
	elif arr[0] == "artifact":
		check = PlayerData.artifact_compare(arr[1])
	# 조건 문자열이 이상할 경우
	else:
		printerr("Condition Error")
		return false
	if negative == check:
		return false
	return true
