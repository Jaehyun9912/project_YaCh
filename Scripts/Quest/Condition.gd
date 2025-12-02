class_name Condition
# 조건 관련 유틸을 넣어놓은 클래스

static var conditionTypes = ["tag", "stat", "item", "artifact", "renown", "money", "map"]

# 무조건 array[0] = boolean, 마지막 = int, 그 직전값은 부등호를 사용
static func string_to_condition(condition: String) -> Array:
	var values = []
	# 긍정 부정 확인
	var negative = false
	if condition.begins_with("!"):
		condition = condition.right(-1)
		negative = true
	values.append(negative)
	var arr = condition.split(":", true)
	# default문 일 경우 tag삽입
	if !conditionTypes.has(arr[0]):
		print(arr[0])
		arr.insert(0, "tag")
	values.append_array(arr)
	return arr

static func submit_to_condition(submit: String) -> String:
	var part = submit.split("-", true, 2)
	return part[0] + ">" + part[1]


# 개별 조건 확인
static func check_condition(condition: String) -> bool:
	# 반전 확인
	var list = string_to_condition(condition)
	# 조건 분야 확인(태그, 아이템, 스탯)
	var check: bool
	if list[1] == "tag":
		if TagService.has_method("tag_compare"):
			# format = [negative,tag,태그id]
			check = TagService.cmp_tag(PlayerData, list[2])
	elif list[1] == "stat":
		# format = [negative,stat,스탯조건(power>5)]
		check = PlayerData.cmp_stat(list[2])
	elif list[1] == "item":
		# format = [negative,item,아이템조건]
		check = PlayerData.cmp_item(list[2])
	elif list[1] == "artifact":
		# format = [negative,artifact,아티펙트id]
		check = PlayerData.cmp_artifact(list[2])
	elif list[1] == "renown":
		# format = [negative,renown,평판조건]
		check = PlayerData.cmp_renown(list[2])
	elif list[1] == "money":
		# format = [negative,money,돈조건]
		check = PlayerData.cmp_money(list[2])
	elif list[1] == "map":
		# format = [negative,map,맵,location] 또는 [negative,map,맵]
		check = PlayerData.cmp_map(list.slice(1))
	# 그 외 조건이 있는지 확인하고 없으면 데이터 에러로 판별
	else:
		printerr("데이터 형식 오류")
		return false
	if list[0] == check:
		return false
	return true
