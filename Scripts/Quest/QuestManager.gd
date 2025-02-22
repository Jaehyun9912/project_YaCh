class_name QuestManager
extends Node

# 태그 상수
const ACCEPT_TREE = "Quest.acceptable."
const UNACCEPT_TREE = "Quest.unacceptable."
const PROCESS_TREE = "Quest.process."
const CLEAR_TREE = "Quest.clear."

# 해당 이름 기준으로 json파일 로드
var npc_name : String

# NPC가 제공하는 퀘스트 리스트
var quest_list : Array[Quest]

# 수주 가능한 퀘스트
var quest_queue : Array[Quest]




# 퀘스트 매니저 생성자
func _init(name : String):
	npc_name = name
	_import_quest()
	enqueue_quest()


# 퀘스트 수주 조건 확인(수주 가능 여부 반환)
func check_quest(quest : Quest)-> bool:
	#퀘스트를 수주 중일 때는 추가 수주 불가능
	if TagManager.has_tag(PlayerData,PROCESS_TREE+quest.id):
		return false
	#수주에 필요한 태그 존재여부 확인
	if !Quest.condition_check(quest.accept_condition):
		return false
	return true


# 퀘스트 리스트에서 수주 가능한 퀘스트를 큐에 추가
func enqueue_quest() -> Array[Quest]:
	# 퀘스트 큐 초기화
	quest_queue.clear()
	for i in quest_list:
		if check_quest(i):
			quest_queue.append(i)
			# 태그 수주 가능으로 변경
			TagManager.remove_tag_tree(self,UNACCEPT_TREE+i.id)
			TagManager.add_tag_tree(self,ACCEPT_TREE+i.id)
	# 수주 가능한 퀘스트 리스트 반환
	return quest_queue


# 퀘스트 수주
func receive_quest(quest : Quest) -> bool:
	# 수주 가능 여부 확인
	if !check_quest(quest):
		printerr("퀘스트 수주 불가!")
		return false
	# 퀘스트 매니저 태그 수주 가능 -> 수주 중으로 전환
	TagManager.remove_tag_tree(self,ACCEPT_TREE+quest.id)
	TagManager.add_tag_tree(self,PROCESS_TREE+quest.id)
	# 수주
	PlayerData.receive_quest(quest)
	return true


# 퀘스트 클리어
func clear_quest(quest: Quest) -> bool:
	# 클리어 가능 여부 확인
	if !quest.is_clearable(npc_name):
		return false		
		printerr("퀘스트 클리어 불가!")
	# 수주중 태그 삭제 후 클리어 태그 부여
	TagManager.remove_tag_tree(self,PROCESS_TREE+quest.id)
	TagManager.add_tag_tree(self,CLEAR_TREE+quest.id)
	# 클리어
	PlayerData.clear_quest(quest)
	submit_item(quest)
	give_reward(quest)
	#print(quest.id , " Clear")
	return true


# 보상 지급
func give_reward(quest : Quest):
	var rewards = quest.rewards
	for i in rewards:
		PlayerData.add_new_item(i.id,i.count)


# 제출 아이템 회수
func submit_item(quest : Quest):
	var submit = quest.submit
	for i in submit:
		PlayerData.add_new_item(i.id,-i.count)


# json에서 npc_name의 퀘스트 로드
func _import_quest() -> void:
	quest_list.clear()
	var data = DataManager.get_data("Quest/"+npc_name)
	#print(data)
	for datum in data[npc_name]:
		var quest = Quest.new(datum)
		quest_list.append(quest)
		# 플레이어에 태그(process,clear)있는지 확인 후 맞게 조정
		var tag = TagManager.find_tag(PlayerData,quest.id) as String
		var count = TagManager.get_tag_count(PlayerData,tag)
		if tag == "":
			TagManager.add_tag_tree(self,UNACCEPT_TREE+quest.id)
		elif tag.begins_with("Quest.process"):
			TagManager.add_tag_tree(self,PROCESS_TREE+quest.id)
		elif tag.begins_with("Quest.clear"):
			TagManager.add_tag_tree(self,CLEAR_TREE+quest.id,count)
			TagManager.add_tag_tree(self,UNACCEPT_TREE+quest.id)


