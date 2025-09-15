class_name Condition

# 조건
var condition: String
var partials: Array

# 해당 조건 충족 확인
var check: bool

func _init(_condition):
	condition = _condition
	check = Quest.check_condition(condition)
	if !check:
		var negative = false
		if condition.begins_with("!"):
			condition = condition.right(-1)
			negative = true
		# 조건 분야 확인(태그, 아이템, 스탯)
		var arr = condition.split(":", true, 1)

		if negative:
			arr[0] = "!" + arr[0]

		if arr.size() == 1:
			partials.append(arr[0])
			TagManager.on_tag_changed.connect(_check_tag) # 퀘스트 별로 태그를 대분류에 맞게 또 분기해야함
		elif arr[0] == "tag":
			partials.append(arr[1])
			TagManager.on_tag_changed.connect(_check_tag)
		elif arr[0] == "stat":
			#check = PlayerData.stat_compare(arr[1])
			pass
		elif arr[0] == "item":
			partials.append(arr[1])
			PlayerData.on_inventory_changed.connect(_check_inventory)
		elif arr[0] == "artifact":
			partials.append(arr[1])
			PlayerData.on_inventory_changed.connect(_check_artifact)
	else:
		print(condition, "clear")

	
func _check_tag(node: Node, _tag: String, _count: int):
	if node != PlayerData:
		return
	check = TagManager.tag_compare(PlayerData, partials[0])
	if check:
		print(partials[0], "clear")
		TagManager.on_tag_changed.disconnect(_check_tag)

func _check_inventory(_id: String, _count: int):
	check = PlayerData.item_compare(partials[0])
	if check:
		print(partials[0], "clear")
		PlayerData.on_inventory_changed.disconnect(_check_inventory)

func _check_artifact(_id: String):
	check = PlayerData.artifact_compare(partials[0])
	if check:
		print(partials[0], "clear")
		PlayerData.on_inventory_changed.disconnect(_check_artifact)
