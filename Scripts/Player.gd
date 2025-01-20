extends Node
class_name Player

const max_inventory_slots = 9

func _ready():
	load_player()
	
#region Data
var data : Dictionary

# data에서 알아서 값을 뽑아오거나 넣어줌 
var max_hp:
	get:
		return data["max_hp"]
	set(value):
		data["max_hp"] = value

var hp:
	get:
		return data["hp"]
	set(value):
		data["hp"] = value

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
var inventory_slot_status : Array[bool]

var artifact:
	get:
		return data["artifacts"]
	set(value):
		data["artifacts"] = value
		
# data 저장 
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
func add_new_item(id : String, count : int):
	var sp = id.split(":")
	var item
	# 아이템 로드 및 검증 
	if sp.size() == 1:
		item = DataManager.get_item_data(sp[0])
		id = "item:"+sp[0]
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
			flag = true
			break
	# 없을 때는 새로 추가 
	if flag == false:
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
	print(id)
	print(inventory)

# 아티팩트 획득 
func _get_artifact(id : String):
	var item = DataManager.get_artifact_data(id)
	print(id," : ",item)
	# 파일 형식 체크 
	if item.size() == 0:
		printerr("Wrong Artifact ID! " + id)
	elif item.has("location") == false:
		printerr("No Location " + id)
	elif ViewManager.now_map_name != item["location"]:
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

#endregion



#region Quest
#수주 중인 퀘스트 리스트
var quest_list : Array[Quest]
#값 비교용

func receive_quest(quest : Quest):
	quest_list.append(quest)
	print( quest.id," Receive, Current QuestCount :",quest_list.size())

#스탯값 부등호 비교
func stat_compare(condition : String) -> bool:
	#퀘스트에 필요한 태그 확인(부등호로 태그 카운트 세기)
	var comparer = [">" , "<", "="]#필요하면 이상 이하도 추가
	for i in comparer:
		var str = condition.split(i,true,2)
		if str.size()==2:
			print(data[str[0]]," ",i," ",str[1])
			#태그가 있는지 없는지부터 확인
			if !data.has(str[0]):
				return false
			if i == ">" && data[str[0]] > str[1].to_int():
				return true
			elif i == "<" && data[str[0]] < str[1].to_int():
				return true
			elif i == "=" && data[str[0]] == str[1].to_int():
				return true
			else:
				return false
	return false

#인벤토리 아이템 개수 확인
func item_compare(condition : String) -> bool:
	var comparer = [">" , "<", "="]#필요하면 이상 이하도 추가
	for i in comparer:
		var str = condition.split(i,true,2)
		if str.size()==2:
			#해당 아이템이 인벤토리에 얼마나 있는지 확인
			var item_count = get_item_count(str[0])
			print(str[0],".count : ",item_count)
			if i == ">" && item_count > str[1].to_int():
				return true
			elif i == "<" && item_count < str[1].to_int():
				return true
			elif i == "=" && item_count == str[1].to_int():
				return true
			else:
				return false
	#비교값이 없을 때는 있는지 없는지만 확인
	var item_count = get_item_count(condition)
	if item_count>0:
		return true
	return false

#플레이어가 해당 아티펙트를 가지고 있는지 확인
func artifact_compare(condition : String) -> bool:
	print(condition,"//",artifact)
	return artifact.has(condition)

#플레이어 인벤토리에 아이템이 몇개 있는지 확인
func get_item_count(id : String) -> int:
	for i in inventory:
		if i["id"] == "item:"+id:
			return i["count"]
	return 0



#endregion
