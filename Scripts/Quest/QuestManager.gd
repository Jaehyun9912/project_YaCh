extends Node3D
class_name QuestManager

@export var NPC_name : String

#캐릭터가 제공하는 퀘스트 리스트
var quest_list : Array[Quest]
#수주 가능한 퀘스트
var quest_queue : Array[Quest]

#퀘스트 수주 조건 확인(수주 가능 여부 반환)
func check_quest(quest : Quest)-> bool:
	#print("Player tag",TagManager.get_tags(PlayerData))
	#퀘스트를 수주 중일 때는 추가 수주 불가능
	if TagManager.has_tag(PlayerData,quest.id):
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
	var str = "Receivable :"
	for i in quest_list:
		if check_quest(i):
			str += " " + i.id
			quest_queue.append(i)
	print(str)
	return !quest_queue.is_empty()

#json에서 퀘스트 로드
func import_quest():
	quest_list.clear()
	var data = DataManager.get_data("Quest/"+NPC_name)
	#print(data)
	for datum in data[NPC_name]:
		var quest = Quest.new(datum)
		quest_list.append(quest)
		


# Called when the node enters the scene tree for the first time.
func _ready():
	#json에서 퀘스트 리스트 받아오기
	import_quest()
	
#NPC 상호작용 시
func _on_NPC_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		#플레이어가 가지고 있는 퀘스트 클리어 확인
		for i in PlayerData.quest_list:
			_clear_quest(i)
		
		#수주 가능 퀘스트 정리
		#없으면 실행 X
		if !enqueue_quest():
			print("No Receivable Quest")
			return
		
		#클릭 시 수주 가능 퀘스트 중 첫번째 퀘스트 수주
		if quest_queue.size()>0:
			var quest = quest_queue[0]
			_receive_quest(quest)
		
		
		
		

func _receive_quest(quest : Quest):
	#수주한 퀘스트 태그 추가(이 퀘스트 재 수주 불가능)
	TagManager.add_tag(PlayerData,quest.id)
	#플레이어의 퀘스트 리스트에 퀘스트 추가
	PlayerData.ReceiveQuest(quest)

func _clear_quest(quest: Quest):
	#해당 퀘스트 도착지가 해당 NPC가 맞는지 확인
	if quest.ClearNPCName != NPC_name:
		#print("isNotClearNPC =",quest.ClearNPCName," != ",NPC_name)
		return false
	if !quest.is_clearable():
		return false		
	PlayerData.PrintQuestList()
	#해당 퀘스트 클리어 시 수주중 태그 삭제 후 클리어 태그 부여
	PlayerData.quest_list.erase(quest)
	#퀘스트 진행에 사용 태그들 삭제(퀘스트 진행 태그 트리 삭제)한
	TagManager.remove_tag_tree(PlayerData,quest.id)
	#퀘스트 클리어 태그 추가(Clear태그 없으면 생성)
	var clear_tag = "Clear." + quest.id
	TagManager.add_tag_tree(PlayerData,clear_tag)
	print(quest.id , " Clear")
	#클리어 횟수 1증가(현재 태그 카운트로 태그 적용 횟수(퀘스트 클리어 횟수) 확인 가능 굳이?
	quest.TAG +=1
	return quest.TAG
	#return TagManager.get_tag_count(PlayerData,clear_tag)



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
	
