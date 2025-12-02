class_name QuestManager
extends Node

# 태그 상수
const ACCEPT_TREE = "Quest.acceptable."
const UNACCEPT_TREE = "Quest.unacceptable."
const PROCESS_TREE = "Quest.process."
const CLEAR_TREE = "Quest.clear."

# 해당 이름 기준으로 json파일 로드
var _npc_name: String
var manager_name:
	get:
		return _npc_name

# NPC가 제공하는 퀘스트 리스트
var quest_list: Array

# 수주 가능한 퀘스트
var quest_queue: Array

var tag_service

var guildId: String
# 퀘스트 매니저 생성자
func _init(npc_name: String):
	_npc_name = npc_name
	tag_service = TagService
	
	_import_quest()
	enqueue_quest()
	
	
# 퀘스트 수주 조건 확인 -> 수주 가능 여부 반환
func check_quest(quest: Dictionary) -> bool:
	#퀘스트를 수주 중일 때는 추가 수주 불가능
	if tag_service.has_method("has_tag"):
		if tag_service.has_tag(PlayerData, PROCESS_TREE + quest.id):
			return false
	#수주에 필요한 태그 존재여부 확인
	if quest.has("accept_condition"):
		for i in quest["accept_condition"]:
			if !Condition.check_condition(i):
				return false
	return true


# 퀘스트 리스트에서 수주 가능한 퀘스트를 큐에 추가
func enqueue_quest() -> void:
	# 퀘스트 큐 초기화
	quest_queue.clear()
	for i in quest_list:
		if check_quest(i):
			quest_queue.append(i)
			# 태그 수주 가능으로 변경


# 퀘스트 수주
func receive_quest(quest) -> bool:
	# 수주 가능 여부 확인
	if !check_quest(quest):
		printerr("퀘스트 수주 불가!")
		return false
	# 퀘스트용 토큰 아이템 부여
	if quest.has("tokens"):
		var token = quest["tokens"]
		for i in token:
			PlayerData.add_new_item(i.id, i.count)
	# 수주
	PlayerData.receive_quest(quest)
	return true


# 퀘스트 클리어
func clear_quest(quest) -> bool:
	# 클리어 가능 여부 확인
	if !can_clear_quest(quest):
		printerr("퀘스트 클리어 불가!")
		return false
	
	# 클리어
	PlayerData.clear_quest(quest)
	# 아이템 회수
	if quest.has("submits"):
		var submit = quest["submits"]
		for i in submit:
			PlayerData.add_new_item(i.id, -i.count)
	# 보상 수령
	if quest.has("rewards"):
		var rewards = quest["rewards"]
		for i in rewards:
			PlayerData.add_new_item(i.id, i.count)
	if quest.has("renown"):
		var curRenown = PlayerData.get_guild_renown(guildId)
		PlayerData.set_guild_renown(guildId, curRenown + quest["renown"])
	#print(quest.id , " Clear")
	return true


# json에서 _npc_name의 퀘스트 로드
func _import_quest() -> void:
	quest_list.clear()
	var data = DataManager.get_data("Quest/" + _npc_name)
	#print(data)
	
	# 소속 표시

	guildId = data["guild"]
	# 지역 상관없이 수주가능한 퀘스트 생성
	for datum in data["All"]:
		quest_list.append(datum)
		print("datum : ", datum)
	
	# 특수 지역에서만 받을 수 있는 퀘스트 생성
	var location_quest = ViewManager.cur_meta_data["address"]
	if data.has(location_quest):
		for datum in data[location_quest]:
			quest_list.append(datum)

func can_clear_quest(quest: Dictionary):
	if quest.has("clear_NPC"):
		if quest["clear_NPC"] != _npc_name:
			return false
	if quest.has("id"):
		var id = quest["id"]
		if tag_service.has_method("has_tag"):
			if !tag_service.has_tag(PlayerData, "Quest.process." + id):
				return false
		else:
			return false
	var condition = get_quest_condition(quest)
	for i in condition:
		if !Condition.check_condition(i):
			return false
	return true
	
func get_quest_condition(quest: Dictionary) -> Dictionary:
	var condition: Dictionary
	if quest.has("process_condition"):
		condition = quest["process_condition"] as Dictionary
	if quest.has("submits"):
		for i in quest["submits"]:
			print(i)
			var part = i.split("-", true, 2)
			if part.size() == 1:
				continue
			var combine = part[0] + ">" + part[1]
			condition[combine] = quest["submits"][i]
	print(condition)
	return condition
