extends Node
class_name Player

const max_inventory_slots = 9

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

func _ready():
	load_player()

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
	if item.size() == 0:
		printerr("Wrong Artifact ID! " + id)
	elif item.has("location") == false:
		printerr("No Location " + id)
	#elif ViewManager.now_map_name != item["location"]:
		#printerr("need same location " + ViewManager.now_map_name + " != " + item["location"])
		#return
	elif item.has("type") == false:
		printerr("No type " + id)
	elif artifact.has(id) == true:
		printerr("Already has Artifact!" + id)
	else:
		artifact[id] = true
		print(artifact)

#endregion

