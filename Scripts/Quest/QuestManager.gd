extends Area3D
class_name QuestManager

#캐릭터가 제공하는 퀘스트 리스트
var quest_list : Array[Quest]
#수주 가능한 퀘스트
var receviable_quest : Array[Quest]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_NPC_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("NPC Clicked : " + name)
		var quest = _get_first_receivable_quest()
		if quest == null:
			return
		
	
#수주 가능 퀘스트 리스트 생성
func _set_recevialbe_quest():
	receviable_quest.clear()
	for n in quest_list.size():
		if quest_list[n]._is_receviable():
			receviable_quest.append(quest_list[n])
		
#디버그용 수주가능 퀘스트 리스트 생성 후 첫번째 퀘스트 수주
func _get_first_receivable_quest():
	_set_recevialbe_quest()
	return receviable_quest.pop_front()
