extends QuestManager


# Called when the node enters the scene tree for the first time.
func _ready():
	#퀘스트 데이터 받아 오고 수주 가능 퀘스트 추가
	import_quest()
	
	enqueue_quest()
	var pos : Vector2
	pos.x = 100
	pos.y = 50
	
	for i in quest_queue:
		set_button(i,pos)
		pos.y+=50
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_button(quest : Quest, pos : Vector2):
	var btn : Button
	btn = Button.new()
	add_child(btn)
	btn.text = quest.id
	btn.set_position(pos)
	btn.button_down.connect(receive_quest.bind(quest))
	btn.button_down.connect(remove_child.bind(btn))
	
	
