extends Node
class_name QuestManager

@export var NPC_name : String

#캐릭터가 제공하는 퀘스트 리스트
var quest_list : Array[Quest]
#수주 가능한 퀘스트
var quest_queue : Array[Quest]

const accept_tree = "Quest.acceptable."
const unaccept_tree = "Quest.unacceptable."
const process_tree = "Quest.process."
const clear_tree = "Quest.clear."


#퀘스트 수주 조건 확인(수주 가능 여부 반환)
func check_quest(quest : Quest)-> bool:
	#퀘스트를 수주 중일 때는 추가 수주 불가능
	if TagManager.has_tag(PlayerData,process_tree+quest.id):
		#print(quest.id," is Already Received")
		return false
	#수주에 필요한 태그 존재여부 확인
	for i in quest.conditions["Before"]:
		if !TagManager.tag_check(PlayerData,i):
			#print(quest.id," is not Receivable")
			return false
	#print(quest.id," is Receivable")
	return true
	

#퀘스트 리스트에서 수주 가능한 퀘스를 큐에 추가
func enqueue_quest():
	#print("EnqueueQuest")
	#퀘스트 큐 초기화
	quest_queue.clear()
	for i in quest_list:
		if check_quest(i):
			quest_queue.append(i)
			#태그 수주 가능으로 변경
			TagManager.remove_tag_tree(self,unaccept_tree+i.id)
			TagManager.add_tag_tree(self,accept_tree+i.id)
	return !quest_queue.is_empty()

#json에서 퀘스트 로드
func import_quest():
	quest_list.clear()
	var data = DataManager.get_data("Quest/"+NPC_name)
	#print(data)
	for datum in data[NPC_name]:
		var quest = Quest.new(datum)
		quest_list.append(quest)
		#플레이어에 태그(process,clear)있는지 확인 후 맞게 조정
		var tag = TagManager.find_tag(PlayerData,quest.id) as String
		var count = TagManager.get_tag_count(PlayerData,tag)
		#태그가 없을 때(수주 중, 클리어 둘다 해당 안될 때)
		if tag == "":
			TagManager.add_tag_tree(self,unaccept_tree+quest.id)
		#해당 태그가 process에 있을 때(수주 중일 때)
		elif tag.begins_with("Quest.process"):
			TagManager.add_tag_tree(self,process_tree+quest.id)
		#해당 퀘스트를 클리어 했을 때(클리어에 횟수 추가 후 태그가 없을 때와 마찬가지)
		elif tag.begins_with("Quest.clear"):
			TagManager.add_tag_tree(self,clear_tree+quest.id,count)
			TagManager.add_tag_tree(self,unaccept_tree+quest.id)
		


# Called when the node enters the scene tree for the first time.
func _ready():
	#할당 해제된 노드 제거(나중에 씬 이동할 때 사용)
	TagManager.clean_dict()
	#json에서 퀘스트 리스트 받아오기
	import_quest()
	print(TagManager.dict)
	
#NPC 상호작용 시
func _on_NPC_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		#플레이어가 가지고 있는 퀘스트 클리어 확인
		
		for i in PlayerData.quest_list:
			clear_quest(i)
		
		#수주 가능 퀘스트 정리
		enqueue_quest()
		
		#클릭 시 수주 가능 퀘스트 중 첫번째 퀘스트 수주
		if quest_queue.size()>0:
			var quest = quest_queue[0]
			receive_quest(quest)
		else:
			print("No Receivable Quest")
		print(TagManager.dict)


#퀘스트 수주(가능한지 확인은 enqueue_quest에서 체크)
func receive_quest(quest : Quest):
	#수주한 퀘스트 태그 추가(이 퀘스트 재 수주 불가능)
	TagManager.add_tag_tree(PlayerData,process_tree+quest.id)
	#퀘스트 매니저 태그 수주 가능 -> 수주 중으로 전환
	TagManager.remove_tag_tree(self,accept_tree+quest.id)
	TagManager.add_tag_tree(self,process_tree+quest.id)
	
	#플레이어의 퀘스트 리스트에 퀘스트 추가
	PlayerData.receive_quest(quest)
	quest_queue.erase(quest)
	

func clear_quest(quest: Quest):
	#해당 퀘스트 도착지가 해당 NPC가 맞는지 확인
	if quest.ClearNPCName != NPC_name:
		#print("isNotClearNPC =",quest.ClearNPCName," != ",NPC_name)
		return false
	if !quest.is_clearable():
		return false		
	#해당 퀘스트 클리어 시 수주중 태그 삭제 후 클리어 태그 부여
	PlayerData.quest_list.erase(quest)
	#퀘스트 진행에 사용 태그들 삭제(퀘스트 진행 태그 트리 삭제)
	TagManager.remove_tag_tree(PlayerData,process_tree+quest.id)
	TagManager.remove_tag_tree(self,process_tree+quest.id)
	#퀘스트 클리어 태그 추가(Clear태그 없으면 생성)
	TagManager.add_tag_tree(PlayerData,clear_tree+quest.id)
	TagManager.add_tag_tree(self,clear_tree+quest.id)
	print(quest.id , " Clear")


#임의의 물체에 태그 부여하기
func add_node_tag(tag,nodeName):
	var node = get_tree().root.get_node(nodeName)
	print(node.name)
	if node ==null:
		printerr("NoNode")
		return
	TagManager.add_tag(tag,node)
	print(TagManager.get_tags(node))
	pass

var Quest_PATH = "res://Data/Quest/"
#디버그용 퀘스트 생성 방식 
func save_quest():
	var children = get_children()
	var arr : Array[Dictionary]
	for child in children:
		if child is Quest:
			var quest = child as Quest
			quest_list.append(quest)
			var qData = quest.get_quest_data()
			arr.append(qData)
	var dict = {
		NPC_name : arr
	}
	save_data(dict,NPC_name)

#디버그용 데이터 저장
func save_data(save: Dictionary, data_path: String) -> void:
	var path = Quest_PATH + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
	
