extends Node
class_name Player

# 아이템 변화 시 (id,count), 아티펙트 변화 시 (id)
signal on_inventory_changed

const max_inventory_slots = 9

func _ready():
	load_player()
	
#region Data
var data: Dictionary
# data에서 알아서 값을 뽑아오거나 넣어줌 
var max_hp:
	get:
		return data["max_hp"]
	set(value):
		data["max_hp"] = value

signal hp_changed
var hp:
	get:
		return data["hp"]
	set(value):
		data["hp"] = value
		hp_changed.emit(value)

var speed:
	get:
		return data["speed"]
	set(value):
		data["speed"] = value

var mana:
	get:
		return data["mana"]
	set(value):
		data["mana"] = value

var skills:
	get:
		return data["skills"]
	set(value):
		data["skills"] = value

var inventory:
	get:
		return data["inventory"]
	set(value):
		data["inventory"] = value
var inventory_slot_status: Array[bool]

var artifact:
	get:
		return data["artifacts"]
	set(value):
		data["artifacts"] = value
		
# data 저장 

var cur_location:
	get:
		if data.has("location"):
			return data["location"]
		else:
			data["location"] = "TestMap"
			return data["location"]
	set(value):
		data["location"] = value

func save_player():
	DataManager.save_data(data, "player")

# user 경로에 저장된 데이터 불러오기 
func load_player():
	var load_data = DataManager.load_data("player") as Dictionary
	
	# 비어있으면 새로 만들기 
	if (load_data.is_empty()):
		reset_player()
		return
	
	# 불러온 데이터 입력하기 
	data = load_data
	inventory_slot_status.resize(max_inventory_slots)
	
	for i in inventory:
		inventory_slot_status[i["slot"]] = true
	

# 새로운 데이터 생성, 이때는 미리 만든 player파일을 가져옴 
func reset_player():
	var new_player = DataManager.get_data("init_player")
	
	data = new_player
	
	DataManager.save_data(data, "player")
#endregion

#region Inventory
func add_new_item(id: String, count: int):
	var sp = id.split(":")
	var item
	# 아이템 로드 및 검증 
	if sp.size() == 1:
		item = DataManager.get_item_data(sp[0])
		id = "item:" + sp[0]
	elif sp[0] == "item":
		item = DataManager.get_item_data(sp[1])
	elif sp[0] == "artifact":
		_get_artifact(sp[1])
		return
	else:
		printerr("Wrong Namespace! " + id)
		return
	
	if item.size() == 0:
		printerr("Wrong Item ID " + id)
		return
	if item.has("type") == false:
		printerr("No item type " + id)
		return
	
	# 아이템 넣기 
	# 이미 아이템 있을 때는 count에 추가 
	var flag = false
	for i in inventory:
		if i["id"] == id:
			i.count += count
			on_inventory_changed.emit(id, i.count)
			if i.count == 0:
				inventory.erase(i)
				print(inventory)
			flag = true
			break
	# 없을 때는 새로 추가 
	if flag == false:
		if count <= 0:
			return
		var first_slot = null
		for i in range(max_inventory_slots):
			if inventory_slot_status[i] == false:
				first_slot = i
				inventory_slot_status[i] = true
				break
		if first_slot == null:
			print("inventory is full")
			return
		var new_item = {"id": id, "count": count, "slot": first_slot}
		inventory.push_back(new_item)
		on_inventory_changed.emit(id, count)
	print(id)
	print(inventory)

# 아티팩트 획득 
func _get_artifact(id: String):
	var item = DataManager.get_artifact_data(id)
	print(id, " : ", item)
	# 파일 형식 체크 
	if item.size() == 0:
		printerr("Wrong Artifact ID! " + id)
	elif item.has("location") == false:
		printerr("No Location " + id)
	elif ViewManager.cur_meta_data["World"] != item["location"]:
		printerr("need same location " + ViewManager.now_map_name + " != " + item["location"])
		return
	elif item.has("type") == false:
		printerr("No type " + id)
	elif artifact.has(id) == true:
		print("Already has Artifact! " + id)
	else:
		# 아이템 부여 
		artifact[id] = true
		print(artifact)
		on_inventory_changed.emit(id)

#endregion


#region Quest

signal quest_updated

# 수주 중인 퀘스트 리스트
var quest_list: Array

@onready var tag_service = DiContainer.get_tag_service()

# 퀘스트 수주(수주중 태그 추가)
func receive_quest(quest):
	quest_list.append(quest)
	#quest.quest_activate()
	if tag_service.has_method("change_tag_tree"):
		tag_service.change_tag_tree(PlayerData, "Quest.process." + quest["id"], 1)
	print(quest["id"], " Receive, Current QuestCount :", quest_list.size())
	quest_updated.emit(quest, true)


# 퀘스트 클리어(클리어 태그 추가)
func clear_quest(quest):
	PlayerData.quest_list.erase(quest)
	if tag_service.has_method("change_tag_tree"):
		tag_service.change_tag_tree(PlayerData, "Quest.process." + quest["id"], 0)
		tag_service.change_tag_tree(PlayerData, "Quest.clear." + quest["id"], 1)
	quest_updated.emit(quest, false)


# 스탯 비교
func stat_compare(condition: String) -> bool:
	var comparer = [">", "<", "="]
	for i in comparer:
		var partial_tag = condition.split(i, true, 2)
		if partial_tag.size() == 2:
			print(data[partial_tag[0]], " ", i, " ", partial_tag[1])
			# 태그 보유 여부 확인
			if !data.has(partial_tag[0]):
				return false
			if i == ">" && data[partial_tag[0]] > partial_tag[1].to_int():
				return true
			elif i == "<" && data[partial_tag[0]] < partial_tag[1].to_int():
				return true
			elif i == "=" && data[partial_tag[0]] == partial_tag[1].to_int():
				return true
			else:
				return false
	return false


# 인벤토리 아이템 개수 비교
func item_compare(condition: String) -> bool:
	var comparer = [">", "<", "="]
	var item_count = 0
	for i in comparer:
		var partial_tag = condition.split(i, true, 2)
		if partial_tag.size() == 2:
			# 아이템이 인벤토리에 얼마나 있는지 확인
			item_count = get_item_count(partial_tag[0])
			print(partial_tag[0], ".count : ", item_count)
			if i == ">" && item_count > partial_tag[1].to_int():
				return true
			elif i == "<" && item_count < partial_tag[1].to_int():
				return true
			elif i == "=" && item_count == partial_tag[1].to_int():
				return true
			else:
				return false
	item_count = get_item_count(condition)
	if item_count > 0:
		return true
	return false


# 아티펙트 보유 여부 확인
func artifact_compare(condition: String) -> bool:
	return artifact.has(condition)


# 보유 중인 아이템 개수 가져오기
func get_item_count(id: String) -> int:
	for i in inventory:
		if i["id"] == "item:" + id:
			return i["count"]
	return 0

#endregion
