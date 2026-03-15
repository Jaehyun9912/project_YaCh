extends Node
# class_name Player

# 아이템 변화 시 (id,count), 아티펙트 변화 시 (id)
signal on_inventory_changed

const max_inventory_slots = 9

var stat_manager: PlayerStat

func _ready():
	stat_manager = PlayerStat.new()

	load_player()
	
#region Stat
# data에서 알아서 값을 뽑아오거나 넣어줌 
# 능력치의 경우 stat_manager를 통해서 처리 (버프, 장비템 처리용)
var max_hp:
	get:
        # 저장된 값이 아니라 계산된 값 호출
		return stat_manager.get_max_hp()

signal hp_changed
var hp: # 현재 hp
	get:
		return stat_manager.get_stat("hp")
	set(value):
		stat_manager.set_stat("hp", value)
		hp_changed.emit(value)

var speed:
	get:
		return stat_manager.get_speed()

var mana: # 현재 mana
# ? mana를 현재 저장할 필요가 있는지 확인 필요 (전투 때 매번 최대치인가?)
	get:
		return stat_manager.get_stat("mana")
	set(value):
		stat_manager.set_stat("mana", value)

var mana_max:
	get:
		return stat_manager.get_max_mana()

var skill_exp: # 숙련도
	get:
		return stat_manager.get_stat("skill_exp", 0)
	set(value):
		stat_manager.set_stat("skill_exp", value)

var skill_level:
	get:
		return stat_manager.get_skill_level()

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

# 스탯 비교
func cmp_stat(condition: String) -> bool:
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

#endregion

#region Data
var data: Dictionary
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

	stat_manager.setup(self, data)
	

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

@onready var tag_service = TagService

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


# 인벤토리 아이템 개수 비교
func cmp_item(condition: String) -> bool:
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
func cmp_artifact(condition: String) -> bool:
	return artifact.has(condition)


# 보유 중인 아이템 개수 가져오기
func get_item_count(id: String) -> int:
	for i in inventory:
		if i["id"] == "item:" + id:
			return i["count"]
	return 0


# 현재 해금된 지역 확인
func cmp_map(arr: Array) -> bool:
	var dict = PlayerData.data
	var last_index = arr.size() - 1
	for i in range(0, last_index):
		print(dict, arr[i])
		if dict.has(arr[i]):
			dict = dict[arr[i]]
		else:
			return false
	return dict.has(arr[last_index])

# 길드 평판 비교
func cmp_renown(condition: String) -> bool:
	var comparer = [">", "<", "="]
	var renown = 0
	for i in comparer:
		var part = condition.split(i, true, 2)
		if part.size() == 2:
			# 아이템이 인벤토리에 얼마나 있는지 확인
			renown = get_guild_renown(part[0])
			if i == ">" && renown >= part[1].to_int():
				return true
			elif i == "<" && renown <= part[1].to_int():
				return true
			elif i == "=" && renown == part[1].to_int():
				return true
			else:
				return false
	renown = get_guild_renown(condition)
	if renown > 0:
		return true
	return false

func cmp_money(condition: String) -> bool:
	var comparer = [">", "<", "="]
	var money = 0
	for i in comparer:
		var part = condition.split(i, true, 2)
		if part.size() == 2:
			# 아이템이 인벤토리에 얼마나 있는지 확인
			money = get_money(part[0])
			if i == ">" && money >= part[1].to_int():
				return true
			elif i == "<" && money <= part[1].to_int():
				return true
			elif i == "=" && money == part[1].to_int():
				return true
			else:
				return false
	money = get_money(condition)
	if money > 0:
		return true
	return false

func execute_cmd(cmd: String) -> void:
	var format = ["+", "-"]
	var list = Condition.string_to_condition(cmd)
	if list[1] == "map":
		# format = [negative, map, mapName, locationName]
		unlock_map(list[2], list[3], list[0])
	elif list[1] == "item":
		# format = [negative,item,아이템 +/- count]
		for i in format:
			var part = list[2].split(i, true)
			if part.size() == 2:
				var count = part[1].to_int()
				if i == "-":
					count *= -1
				add_new_item(part[0], count)
				break
	elif list[1] == "money":
		# format = [negative,money,moneyType +/- count]
		for i in format:
			var part = list[2].split(i, true)
			if part.size() == 2:
				var count = part[1].to_int()
				if i == "-":
					pay_money(part[0], count)
				else:
					add_money(part[0], count)
				break
	else:
		printerr("데이터 형식 오류 : ", cmd)

#endregion	

#region Money

func get_money(money_name: String) -> int:
	if data.has("money"):
		var money = data["money"]
		if money.has(money_name):
			return money[money_name]
	return 0

func set_money(money_name: String, amount: int):
	if data.has("money"):
		var money = data["money"]
		money[money_name] = amount
	else:
		data["money"] = {money_name: amount}

func add_money(money_name: String, amount: int):
	if data.has("money"):
		var money = data["money"]
		if money.has(money_name):
			money[money_name] += amount
		else:
			money[money_name] = amount
	else:
		data["money"] = {money_name: amount}

func pay_money(money_name: String, amount: int) -> bool:
	if data.has("money"):
		var money = data["money"]
		if money.has(money_name):
			if money[money_name] >= amount:
				money[money_name] -= amount
				return true
	return false

#endregion

#region Map

func get_unlock_maps(mapName: String) -> Array:
	if data.has("map"):
		var map = data["map"]
		if map.has(mapName):
			return map[mapName]
	return []

func unlock_map(mapName: String, locationName: String, lock = false):
	if !data.has("map"):
		data["map"] = {}
	
	var arr = get_unlock_maps(mapName)
	if lock:
		arr.erase(locationName)
	else:
		if !arr.has(locationName):
			arr.append(locationName)
	data["map"][mapName] = arr


#endregion

#region Renown

func get_guild_renown(guildId: String) -> int:
	if data.has("renown"):
		var guild = data["renown"]
		if guild.has(guildId):
			return guild[guildId]
	return 0

func set_guild_renown(guildId: String, renown: int):
	if !data.has("renown"):
		data["renown"] = {}
	
	var guild = data["renown"]
	guild[guildId] = renown


#endregion

#region Time

enum TimeZone
{
	MORNING = 0,
	NOON = 1,
	EVENING = 2,
	NIGHT = 3,
}

var _total_time: int

var _time: TimeZone

var time:
	get:
		return _time

@export var action_count: int = 5

var current_action_count: int

signal on_time_changed(time: TimeZone)

func spend_time(count: int):
	# 행동한 가중치만큼 시간 진행
	current_action_count += count
	var zone: int = current_action_count / action_count
	current_action_count %= action_count

	if zone > 0:
		# 시간 진행에 따른 시간대 진행
		_total_time += zone
		_time = _total_time%TimeZone.size() as TimeZone
		on_time_changed.emit(time)
	

	print(time)

func cmp_time(condition: String):
	var comparer = [">", "<", "="]
	for i in comparer:
		if condition.begins_with(i):
			condition = condition.right(-1)
			var value = condition.to_int()
			if i == ">":
				return time >= value
			elif i == "<":
				return time <= value
			elif i == "=":
				return time == value

#endregion

#region ChangeStat

# 숙련도(경험치) 획득
# is_combat: 전투 중 획득 여부 (전투 중이면 마나 소모량 비례 추가)
# mana_consumed: 전투 중 소모한 마나량
func gain_skill_exp(amount: float, is_combat: bool = false, mana_consumed: float = 0):
	stat_manager.add_skill_exp(amount, mana_consumed, is_combat)

# 영구 마나 최대치 증가 
func gain_permanent_mana(amount: float):
	stat_manager.add_permanent_mana(amount)

# 장비 변경 시 스탯 업데이트
func update_equipment_stats(armor_weight: float):
	stat_manager.update_equipment_stats(armor_weight)

# 체력 감소
func apply_damage(amount: float) -> float:
	var damage = stat_manager.calculate_incoming_damage(amount)
	hp -= damage
	return damage


#endregion