extends Node
# class_name Player

# 아이템 변화 시 발생하는 시그널 (id, total_count)
signal on_inventory_changed(id: String, total_count: int)

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

var inventory: InventoryContainer

# 스탯 비교
func cmp_stat(condition: String) -> bool:
	var comparer = [">", "<", "="]
	for i in comparer:
		var partial_tag = condition.split(i, true, 2)
		if partial_tag.size() == 2:
			var stats = data.get("stats", {})
			if !stats.has(partial_tag[0]):
				return false
			
			var val = stats[partial_tag[0]]
			var target = partial_tag[1].to_int()
			
			if i == ">" && val > target:
				return true
			elif i == "<" && val < target:
				return true
			elif i == "=" && val == target:
				return true
			else:
				return false
	return false

#endregion

#region Data
## 실제로 저장되는 데이터
var data: Dictionary

var skills:
	get:
		return data.get("skills", {})
	set(value):
		data["skills"] = value

## 플레이어가 보유한 스킬 정보 반환 (카테고리별, {"active": Array, "unlocked": Array} 형태, 오류 발생시 빈 딕셔너리 반환)
func get_player_skills(type: SkillData.SkillType) -> Dictionary:
	match (type):
		SkillData.SkillType.NORMAL:
			return skills.get("normal", {})
		SkillData.SkillType.SPECIAL_PARRY or SkillData.SkillType.SPECIAL_COUNTER:
			return skills.get("special", {})
		SkillData.SkillType.PEER:
			return skills.get("peer", {})
		_:
			return {}

var cur_location:
	get:
		var meta = data.get("data", {})
		if meta.has("current_location"):
			return meta["current_location"]
		else:
			meta["current_location"] = "TestMap"
			data["data"] = meta
			return meta["current_location"]
	set(value):
		if not data.has("data"): data["data"] = {}
		data["data"]["current_location"] = value


func save_player():
	var inv_contents = inventory.get_inventory_contents()
	
	# 구조 보장
	if not data.has("data"): data["data"] = {}
	if not data.has("stats"): data["stats"] = {}
	if not data.has("inventory"): data["inventory"] = {}
	if not data.has("progress"): data["progress"] = {}
	if not data.has("economy"): data["economy"] = {}

	var init_player = DataManager.get_data("player")
	
	# 메타데이터 업데이트
	data["data"]["saved_versions"] = init_player.get("data", {}).get("saved_versions", "0.0.0")
	data["data"]["last_played"] = Time.get_datetime_string_from_system()
	
	# 계산된 스탯 저장 (스키마 준수용)
	data["stats"]["max_hp"] = max_hp
	data["stats"]["max_mana"] = mana_max
	data["stats"]["speed"] = speed
	
	# 인벤토리 동기화 (모든 아이템이 items 리스트에 저장됨)
	data["inventory"]["items"] = inv_contents
	
	DataManager.save_data(data, "player")

## user 경로에 저장된 데이터 불러오기 
func load_player():
	var load_data = DataManager.load_data("player") as Dictionary
	
	# 비어있으면 새로 만들기 
	if (load_data.is_empty()):
		reset_player()
		return
	
	# 버전 체크
	var saved_version = load_data.get("data", {}).get("saved_versions", "0.0.0")
	var init_player = DataManager.get_data("player")
	var current_version = init_player.get("data", {}).get("saved_versions", "0.0.0")
	if saved_version != current_version:
		printerr("[PlayerData] 세이브 데이터 버전 불일치 (%s -> %s). 개발 중인 버전이므로 데이터를 초기화합니다." % [saved_version, current_version])
		reset_player()
		return
	
	# 불러온 데이터 입력하기 
	data = load_data
	
	# 인벤토리 초기화
	inventory = InventoryContainer.new()
	
	var inv_data = {
		"items": data.get("inventory", {}).get("items", [])
	}
	inventory.set_all_item(inv_data)
	inventory.item_changed.connect(_on_inventory_changed)

	# 스탯 매니저 설정 (stats 서브 딕셔너리 전달)
	if not data.has("stats"): data["stats"] = {}
	stat_manager.setup(self, data["stats"])
	

## 새로운 데이터 생성, 이때는 미리 만든 player파일을 가져옴 
func reset_player():
	var new_player = DataManager.get_data("player")
	data = new_player
	DataManager.save_data(data, "player")
	load_player()
#endregion

#region Inventory
## 아이템 추가, count는 아이템 개수 (음수일 때는 제거)
func add_new_item(id: String, count: int):
	inventory.add_item(id, count)

func _on_inventory_changed(id: String, total_count: int):
	on_inventory_changed.emit(id, total_count)
#endregion

#region Quest

signal quest_updated

# 수주 중인 퀘스트 리스트
var quest_list: Array

@onready var tag_service = TagService

# 퀘스트 수주(수주중 태그 추가)
func receive_quest(quest: QuestData):
	quest_list.append(quest)
	#quest.quest_activate()
	if tag_service.has_method("change_tag_tree"):
		tag_service.change_tag_tree(PlayerData, "Quest.process." + quest.id, 1)
	print(quest.id, " Receive, Current QuestCount :", quest_list.size())
	quest_updated.emit(quest, true)


# 퀘스트 클리어(클리어 태그 추가)
func clear_quest(quest: QuestData):
	PlayerData.quest_list.erase(quest)
	if tag_service.has_method("change_tag_tree"):
		tag_service.change_tag_tree(PlayerData, "Quest.process." + quest.id, 0)
		tag_service.change_tag_tree(PlayerData, "Quest.clear." + quest.id, 1)
	quest_updated.emit(quest, false)


# 인벤토리 아이템 개수 비교
func cmp_item(condition: String) -> bool:
	var comparer = [">", "<", "="]
	var item_count = 0
	for i in comparer:
		var partial_tag = condition.split(i, true, 2)
		if partial_tag.size() == 2:
			# 아이템이 인벤토리에 얼마나 있는지 확인
			item_count = inventory.get_item_count(partial_tag[0])
			print(partial_tag[0], ".count : ", item_count)
			if i == ">" && item_count > partial_tag[1].to_int():
				return true
			elif i == "<" && item_count < partial_tag[1].to_int():
				return true
			elif i == "=" && item_count == partial_tag[1].to_int():
				return true
			else:
				return false
	item_count = inventory.get_item_count(condition)
	if item_count > 0:
		return true
	return false


# 아티펙트 보유 여부 확인
func cmp_artifact(condition: String) -> bool:
	print("Player: Checking artifact condition: ", condition, " clear: ", inventory.get_item_count(condition) > 0)
	return inventory.get_item_count(condition) > 0


# 보유 중인 아이템 개수 가져오기
func get_item_count(id: String) -> int:
	return inventory.get_item_count(id)


# 현재 해금된 지역 확인
func cmp_map(arr: Array) -> bool:
	var params = arr.duplicate()
	if params.size() > 0 and params[0] == "map":
		params.remove_at(0)
	
	if params.size() == 0:
		return false
		
	var map_dict = data.get("progress", {}).get("map", {})
	var map_name = params[0]
	
	if params.size() == 1:
		# 맵 전체 해금 여부 확인
		return map_dict.has(map_name)
	
	# 특정 지역 해금 여부 확인
	var location_name = params[1]
	if map_dict.has(map_name):
		var locations = map_dict[map_name]
		if typeof(locations) == TYPE_ARRAY:
			return locations.has(location_name)
			
	return false

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
	if money_name == "gold":
		return data.get("economy", {}).get("gold", 0)
	return 0

func set_money(money_name: String, amount: int):
	if money_name == "gold":
		if not data.has("economy"): data["economy"] = {}
		data["economy"]["gold"] = amount

func add_money(money_name: String, amount: int):
	if money_name == "gold":
		if not data.has("economy"): data["economy"] = {}
		var current = data["economy"].get("gold", 0)
		data["economy"]["gold"] = current + amount

func pay_money(money_name: String, amount: int) -> bool:
	if money_name == "gold":
		var current = data.get("economy", {}).get("gold", 0)
		if current >= amount:
			data["economy"]["gold"] = current - amount
			return true
	return false

#endregion

#region Map

func get_unlock_maps(mapName: String) -> Array:
	return data.get("progress", {}).get("map", {}).get(mapName, [])

func unlock_map(mapName: String, locationName: String, lock = false):
	if !data.has("progress"): data["progress"] = {}
	if !data["progress"].has("map"): data["progress"]["map"] = {}
	
	var map_dict = data["progress"]["map"]
	if !map_dict.has(mapName): map_dict[mapName] = []
	
	var arr = map_dict[mapName]
	if lock:
		arr.erase(locationName)
	else:
		if !arr.has(locationName):
			arr.append(locationName)
	map_dict[mapName] = arr

#endregion

#region Renown

func get_guild_renown(guildId: String) -> int:
	return data.get("economy", {}).get("guild", {}).get(guildId, 0)

func set_guild_renown(guildId: String, renown: int):
	if !data.has("economy"): data["economy"] = {}
	if !data["economy"].has("guild"): data["economy"]["guild"] = {}
	
	data["economy"]["guild"][guildId] = renown

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