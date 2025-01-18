extends Node
class_name Quest


#퀘스트 비교 목적 값(스탯은 스탯 비교, 그 외엔 data에 스탯 추가)
var id : String
var ClearNPCName : String
var conditions
#수주 조건
var accept_condition:
	get:
		return conditions["Before"]
#클리어 조건
var process_condition:
	get:
		return conditions["Process"]


var rewards


func get_quest_data() -> Dictionary:
	var dict = {
		"id" : id,
		"condition" : conditions,
		"ClearNPCName" : ClearNPCName,
		"rewards" : rewards
	}
	return dict

func _init(data : Dictionary) ->void:
	ClearNPCName = data["ClearNPCName"]
	id = data["id"]
	conditions = data["condition"]
	rewards = data["rewards"]
	
#퀘스트 클리어 조건 확인하기
func is_clearable() -> bool:
	if !TagManager.has_tag(PlayerData,"Quest.process."+id):
		return false
	#클리어 조건 확인 후 가능하면 true 반환
	if Quest.condition_check(process_condition):
		return true
	return false

#조건 문자열 배열로 받아서 순회. 하나라도 미충족 시 false 반환
static func condition_check(condition : PackedStringArray)-> bool:
	for i in condition:
		print("process1 : ",i)
		#반전 확인
		var negative = false
		var str = i
		if str.begins_with("!"):
			str = str.right(-1)
			negative = true
		print("process2 : ",str)
		#조건 분야 확인(태그, 아이템, 스탯)
		var arr = str.split(":",true,1)
		print("process3 : ",arr)
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
		print("result : ", negative != check)
		if negative == check:
			return false
	return true
