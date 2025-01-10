extends Node
class_name Quest


var TAG : int
#퀘스트 비교 목적 값(스탯은 스탯 비교, 그 외엔 data에 스탯 추가)
#var value : Dictionary
@export var id : String
@export var ClearNPCName : String
var conditions
#Before : 수주에 필요한 태그(태그 : 카운트)
#NonBefore : 수주에 없어야하는 태그(태그 배열)
#Process : 클리어에 필요한 태그(태그 : 카운트)
#NonProcess : 클리어에 없어야하는 태그(태그 배열)
#수주 중일 때 태그 id 값 부여
#클리어 시 태그 id + "C" 값 부여

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func is_met():
	pass
	
func get_quest_data() -> Dictionary:
	var dict = {
		"TAG" : TAG,
		"id" : id,
		"condition" : conditions,
		"ClearNPCName" : ClearNPCName
	}
	return dict

func _init(data : Dictionary) ->void:
	ClearNPCName = data["ClearNPCName"]
	TAG = data["TAG"]
	id = data["id"]
	conditions = data["condition"]
	
#퀘스트 클리어 태그 확인하기(카운트는 체크 안함)
func is_clearable():
	if !TagManager.has_tag(PlayerData,id):
		return false
	#퀘스트에 필요한 태그 확인
	for i in conditions["Process"]:
		if !TagManager.has_tag(PlayerData,i):
			print(id," Can't Clear")
			return false
	for i in conditions["NonProcess"]:
		if TagManager.has_tag(PlayerData,i):
			print(id," Can't Clear")
			return false
	#퀘스트 클리어 조건을 모두 충족함
	return true
