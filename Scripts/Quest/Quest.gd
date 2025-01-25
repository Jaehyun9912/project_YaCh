extends Node
class_name Quest

#퀘스트 데이터
var data
#퀘스트 id
var id:
	get:
		if data.has("id"):
			return data["id"]
		else:
			return ""
#퀘스트 제목
var title:
	get:
		if data.has("title"):
			return data["title"]
		else:
			return ""
#퀘스트 설명
var description:
	get:
		if data.has("description"):
			return data["description"]
		else:
			return ""
#퀘스트 클리어 NPC(다른 NPC한테서 퀘스트 클리어 불가능)
var clear_NPC:
	get:
		if data.has("clear_NPC"):
			return data["clear_NPC"]
		return null
#수주 조건
var accept_condition:
	get:
		if data.has("accept_condition"):
			return data["accept_condition"]
		return PackedStringArray()
#클리어 조건
var process_condition:
	get:
		if data.has("process_condition"):
			return data["process_condition"]
		return PackedStringArray()
#제출 아이템(해당 개수도 조건에 자동으로 포함)
var submit:
	get:
		if data.has("submit"):
			return data["submit"]
		return PackedStringArray()
#보상 아이템
var rewards:
	get:
		if data.has("rewards"):
			return data["rewards"]
		return PackedStringArray()


func get_quest_data() -> Dictionary:
	var dict = {
		"title" : title,
		"description" : description,
		"id" : id,
		"accept_condition" : accept_condition,
		"process_condition" : process_condition,
		"clear_NPC" : clear_NPC,
		"rewards" : rewards
	}
	return dict

func _init(quest_data : Dictionary) ->void:
	data = quest_data
	
#퀘스트 클리어 조건 확인하기
func is_clearable(npc_name : String) -> bool:
	#해당 퀘스트 도착지가 해당 NPC가 맞는지 확인
	if clear_NPC != npc_name:
		#print("isNotClearNPC =",quest.clear_NPC," != ",npc_name)
		return false
	if !TagManager.has_tag(PlayerData,"Quest.process."+id):
		return false
	#클리어 조건 확인 후 가능하면 true 반환
	var condition = process_condition as Array[String]
	for i in submit:
		var str = "!item:"+i["id"]+"<" + str(i["count"])
		condition.append(str)
	if Quest.condition_check(condition):
		return true
	return false

#조건 문자열 배열로 받아서 순회. 하나라도 미충족 시 false 반환
static func condition_check(condition : PackedStringArray)-> bool:
	for i in condition:
		#print("process1 : ",i)
		#반전 확인
		var negative = false
		var str = i
		if str.begins_with("!"):
			str = str.right(-1)
			negative = true
		#print("process2 : ",str)
		#조건 분야 확인(태그, 아이템, 스탯)
		var arr = str.split(":",true,1)
		#print("process3 : ",arr)
		var check : bool
		if arr.size()==1:
			check = TagManager.tag_compare(PlayerData,arr[0])
		elif arr[0] == "tag":
			check = TagManager.tag_compare(PlayerData,arr[1])
		elif arr[0] == "stat":
			check = PlayerData.stat_compare(arr[1])
		elif arr[0] == "item":
			check = PlayerData.item_compare(arr[1])
		elif arr[0] == "artifact":
			check = PlayerData.artifact_compare(arr[1])
		#조건 문자열이 이상할 경우
		else:
			printerr("Condition Error")
			return false
		print(i," : ", negative != check)
		if negative == check:
			return false
	return true
