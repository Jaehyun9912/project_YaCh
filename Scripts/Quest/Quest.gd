extends Node
class_name Quest


var TAG : int
var count : int
@export var id : String
@export var ClearNPCName : String
var conditions ={
	"Before" : ["A"],
	"NonBefore" : ["A-1"],
	"Process" : ["B"],
	"NonProcess" : ["B-1"]
}
#Before : 수주에 필요한 태그
#NonBefore : 수주에 없어야하는 태그
#Process : 클리어에 필요한 태그
#NonProcess : 클리어에 없어야하는 태그
#수주 중일 때 태그 id 값 부여
#클리어 시 태그 id + "C" 값 부여

func Setcount(i : int):
	count = i
		

func countUp(i : int):
	Setcount(count + i)
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
	
func Quest_Count():
	pass
