extends Node
class_name QuestManager

@export var npc_name : String

#캐릭터가 제공하는 퀘스트 리스트
var quest_list : Array[Quest]
#수주 가능한 퀘스트
var quest_queue : Array[Quest]

const accept_tree = "Quest.acceptable."
const unaccept_tree = "Quest.unacceptable."
const process_tree = "Quest.process."
const clear_tree = "Quest.clear."

signal quest_updated
var ui_open : bool
#퀘스트 수주 조건 확인(수주 가능 여부 반환)
func check_quest(quest : Quest)-> bool:
	#퀘스트를 수주 중일 때는 추가 수주 불가능
	if TagManager.has_tag(PlayerData,process_tree+quest.id):
		return false
	#수주에 필요한 태그 존재여부 확인
	if !Quest.condition_check(quest.accept_condition):
		return false
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
	return quest_queue
	quest_updated.emit()

#json에서 퀘스트 로드
func import_quest():
	quest_list.clear()
	var data = DataManager.get_data("Quest/"+npc_name)
	#print(data)
	for datum in data[npc_name]:
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

func show_manager_panel():
	var panel = ViewManager.push_panel("QuestManagerPanel")
	panel.tree_exited.connect(func(): ui_open = false)
	#본인에 대한 퀘스트 조건, 수주 가능한 퀘스트 리스트 설정
	panel.set_panel(self)
	ui_open = true


#NPC 상호작용 시
func _on_NPC_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		if !ui_open:
			show_manager_panel()


#퀘스트 수주(가능한지 확인은 enqueue_quest에서 체크)
func receive_quest(quest : Quest):
	#퀘스트 매니저 태그 수주 가능 -> 수주 중으로 전환
	TagManager.remove_tag_tree(self,accept_tree+quest.id)
	TagManager.add_tag_tree(self,process_tree+quest.id)
	#퀘스트 명, 클리어 조건 서술
	print(quest.title ," 수주 : " , quest.description)
	#플레이어의 퀘스트 리스트에 퀘스트 추가
	PlayerData.receive_quest(quest)
	quest_updated.emit()

func clear_quest(quest: Quest):
	#클리어 가능 여부 확인
	if !quest.is_clearable(npc_name):
		return false		
	PlayerData.clear_quest(quest)
	#본인에 수주중 태그 삭제 후 클리어 태그 부여
	TagManager.remove_tag_tree(self,process_tree+quest.id)
	TagManager.add_tag_tree(self,clear_tree+quest.id)
	#퀘스트 보상 부여
	submit_item(quest)
	give_reward(quest)
	print(quest.id , " Clear")
	quest_updated.emit()

func give_reward(quest : Quest):
	#보상 값 순회하면서 플레이어 인벤에 추가하기
	#퀘스트 조건으로 아이템 가져가는 거 체크로 개수 확인 하고 보상에 -개수 넣으면 될듯?
	var rewards = quest.rewards
	for i in rewards:
		PlayerData.add_new_item(i.id,i.count)

func submit_item(quest : Quest):
	var submit = quest.submit
	for i in submit:
		PlayerData.add_new_item(i.id,-i.count)
	



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
		npc_name : arr
	}
	save_data(dict,npc_name)

#디버그용 데이터 저장
func save_data(save: Dictionary, data_path: String) -> void:
	var path = Quest_PATH + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	save_file.store_line(json_string)
	

