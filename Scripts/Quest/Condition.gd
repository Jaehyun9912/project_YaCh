class_name Condition

func _init(condition: String):
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
		check = TagManager.tag_compare(PlayerData, arr[0])
	elif arr[0] == "tag":
		check = TagManager.tag_compare(PlayerData, arr[1])
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
