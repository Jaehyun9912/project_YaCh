class_name Condition
# 조건 관련 유틸을 넣어놓은 클래스


# 개별 조건 확인
static func check_condition(condition: String) -> bool:
	# 반전 확인
	var negative = false
	if condition.begins_with("!"):
		condition = condition.right(-1)
		negative = true
	# 조건 분야 확인(태그, 아이템, 스탯)
	var arr = condition.split(":", true)
	var check: bool
	if arr.size() == 1:
		if TagService.has_method("tag_compare"):
			check = TagService.tag_compare(PlayerData, arr[0])
	elif arr[0] == "tag":
		if TagService.has_method("tag_compare"):
			check = TagService.tag_compare(PlayerData, arr[1])
	elif arr[0] == "stat":
		check = PlayerData.stat_compare(arr[1])
	elif arr[0] == "item":
		check = PlayerData.item_compare(arr[1])
	elif arr[0] == "artifact":
		check = PlayerData.artifact_compare(arr[1])
	# 그 외 조건이 있는지 확인하고 없으면 데이터 에러로 판별
	else:
		print(arr)
		check = PlayerData.check_data(arr)
	if negative == check:
		return false
	return true


# 마지막 딕셔너리에서 조건문을 부등호로 split하고 왼쪽 key값을 마지막 딕셔너리에 넣어서 value를 가져옴
# 해당 value와 오른쪽 값을 부등호로 비교해서 true false 반환
static func dict_compare(data, compare: String) -> bool:
	var comparer = [">", "<", "="]
	for i in comparer:
		var sub_str = compare.split(i, true, 2)
		print(sub_str)
		if sub_str.size() == 2:
			if i == ">":
				if data.has(sub_str[0]):
					return data[sub_str[0]] >= sub_str[1].to_int()
				else:
					return false
			elif i == "<":
				if data.has(sub_str[0]):
					return data[sub_str[0]] <= sub_str[1].to_int()
				else:
					return true
			elif i == "=":
				if data.has(sub_str[0]):
					return data[sub_str[0]] == sub_str[1].to_int()
				else:
					return false
			else:
				return false
	# 부등호 비교문이 없으면 해당 아이템이 있는지 없는지 확인
	if data is Array:
		if data.has(compare):
			return true
	return false
