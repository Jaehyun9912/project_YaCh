class_name Condition
# 조건 관련 유틸을 넣어놓은 클래스

# 무조건 array[0] = boolean, 마지막 = int, 그 직전값은 부등호를 사용
static func string_to_condition(condition: String) -> Array:
	var values = []
	var negative = false
	if condition.begins_with("!"):
		condition = condition.right(-1)
		negative = true
	values.append(negative)
	var arr = condition.split(":", true)
	var last = arr[arr.size() - 1]
	arr.remove_at(arr.size() - 1)
	values.append_array(arr)
	var comparer = [">", "<", "="]
	for i in comparer:
		var part = last.split(i, true)
		if part.size() > 1:
			arr.append(part[0])
			arr.append(i)
			arr.append(part[1])
			return arr
	arr.append(last)
	arr.append(">")
	arr.append("1")
	return arr


# 개별 조건 확인
static func check_condition(condition: String) -> bool:
	# 반전 확인
	var list = string_to_condition(condition)
	# 조건 분야 확인(태그, 아이템, 스탯)
	var check: bool
	if list[1] == "tag":
		if TagService.has_method("tag_compare"):
			check = TagService.tag_compare(PlayerData, list[1])
	elif list[1] == "stat":
		check = PlayerData.stat_compare(list[1])
	elif list[1] == "item":
		check = PlayerData.item_compare(list[1])
	elif list[1] == "artifact":
		check = PlayerData.artifact_compare(list[1])
	elif list[1] == "renown":
		check = PlayerData.check_data(list)
	elif list[1] == "money":
		check = PlayerData.check_data(list)
	# 그 외 조건이 있는지 확인하고 없으면 데이터 에러로 판별
	else:
		printerr("데이터 형식 오류")
		return false
	if list[0] == check:
		return false
	return true


# 마지막 딕셔너리에서 조건문을 부등호로 split하고 왼쪽 key값을 마지막 딕셔너리에 넣어서 value를 가져옴
# 해당 value와 오른쪽 값을 부등호로 비교해서 true false 반환
static func dict_compare(data, compare: String) -> bool:
	var comparer = [">", "<", "="]
	for i in comparer:
		var sub_str = compare.split(i, true, 2)
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
