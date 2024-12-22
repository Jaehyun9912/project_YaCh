extends Area3D
class_name QuestManager

#매니저가 갖고있는 모든 퀘스트들
var quest_list : Array[Quest]
#수주 가능한 퀘스트 리스트
var receivable_quest : Array[Quest]
#수주 중인 퀘스트
var processing_quest : Array[Quest]
#완료 가능한 퀘스트 리스트
var finishable_quest : Array[Quest]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_NPC_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		#클리어 처리 가능 퀘스트 확인
		
		#수주 가능 퀘스트 확인
		_set_receivable_quest()
		var new_quest = receivable_quest.pop_front()
		if new_quest == null:
			print("No More Quest")
			return
		processing_quest.append(new_quest)
		
		print("Location Clicked : " + name)


func _set_receivable_quest():
	receivable_quest.clear()
	for n in quest_list.size():
		if quest_list[n]._is_receivable():
			receivable_quest.append(quest_list[n])

func _set_finishable_quest():
	finishable_quest.clear()
	for n in processing_quest.size():
		if processing_quest[n]._is_finishable():
			finishable_quest.append(processing_quest[n])
