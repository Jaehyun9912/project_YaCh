class_name Condition
# 조건 관련 유틸을 넣어놓은 클래스
# 조건문은 두 종류(명령문, 비교문)이 존재한다.
# 명령문 -> 비교문으로 변환 가능하나 역은 불가하다.
# 


static var conditionTypes = ["tag", "stat", "item", "artifact", "renown", "money", "map", "time"]

# string 형태의 조건문을 string 배열 형태의 명령문/비교문으로 변환한다.
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
		arr.insert(0, "tag")
	values.append_array(arr)
	return values

# 명령문을 비교문으로 변환한다.
static func cmd_to_cmp(submit: String) -> String:
	var condition = submit
	# 아티펙트 회수나 지역 잠금인지 확인
	if submit.begins_with("!"):
		condition = submit.right(-1)
	var part = condition.split("-", true, 2)
	# 아이템, 돈 회수인지 확인
	if part.size() == 2:
		condition = part[0] + ">" + part[1]
	# 명령문에서 비교문으로 전환후 condition으로 전환해서 반환
	return condition


# 개별 조건 확인
static func check_condition(condition: String) -> bool:
	# 반전 확인
	var list = string_to_condition(condition)
	# 조건 분야 확인(태그, 아이템, 스탯)
	var check: bool
	if list[1] == "tag":
		if TagService.has_method("cmp_tag"):
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
	elif list[1] == "time":
		# format = [negative, time, ><= Time(int)]
		check = PlayerData.cmp_time(list[2])
	# 그 외 조건이 있는지 확인하고 없으면 데이터 에러로 판별
	else:
		printerr("데이터 형식 오류 : ", condition)
		return false
	if list[0] == check:
		return false
	return true

# 조건 리스트 내부의 조건 확인, 모두 만족할 경우 true 반환
static func check_conditions(conditions: PackedStringArray) -> bool:
	for i in conditions:
		if !check_condition(i):
			return false
	return true