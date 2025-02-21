extends Control

# 퀘스트 매니저
var quest_manager :
	set(manager):
		quest_manager = manager as QuestManager

# 디테일 패널 모드 enum 과 같음
enum Mode{
	receive, 
	process, 
	clear
}




# 퀘스트 매니저 생성 후 패널 표시
func _ready():
	var npc_name# = get_meta("npc_name")
	if not npc_name:
		npc_name = ViewManager.now_map_name
	print(npc_name)
	quest_manager = QuestManager.new(npc_name)
	#왼쪽 패널 업데이트
	update_accept_panel()
	#오른쪽 패널 업데이트
	update_panel()


# 왼쪽 패널에 수주 가능한 퀘스트 리스트 업데이트
func update_accept_panel():
	var parent = $QuestList/ScrollContainer/VBoxContainer
	quest_manager.enqueue_quest()
	for i in parent.get_children():
		i.queue_free()
	#리스트에 해당하는 퀘스트 버튼 생성
	for i in quest_manager.quest_queue:
		var button = set_quest_button(i,parent)
		#퀘스트 수주 모드로 디테일 패널 열기
		button.pressed.connect($"QuestDetail".set_quest.bind(i,Mode.receive))


# 오른쪽 패널 현재 수주중인 퀘스트 리스트 업데이트
func update_panel():
	var parent = $QuestList2/ScrollContainer/VBoxContainer
	for i in parent.get_children():
		i.queue_free()
	#리스트에 해당하는 퀘스트 버튼 생성
	for i in PlayerData.quest_list:
		var button = set_quest_button(i,parent)
		#클리어 가능하면 옵션 버튼 활성화 아니면 비활성화
		if i.is_clearable(quest_manager.npc_name):
			#클리어 가능한 퀘스트는 버튼 색 변경
			var style = StyleBoxFlat.new()
			style.bg_color = Color.CHOCOLATE
			button.add_theme_stylebox_override("normal", style)
			
			button.pressed.connect($"QuestDetail".set_quest.bind(i,Mode.clear))
		else:
			button.pressed.connect($"QuestDetail".set_quest.bind(i,Mode.process))


# 단일 버튼 생성 후 퀘스트와 바인딩
func set_quest_button(quest : Quest,parent):
	var button = Button.new()
	button.text = quest.title
	button.pressed.connect(func(): $"QuestDetail".show())
	parent.add_child(button)
	return button


# 디테일 패널의 option_pressed 시그널 연결
func detail_interact(quest, mode : Mode):
	# 현재 모드에 맞는 함수 실행
	if mode == Mode.process:
		return
	elif mode == Mode.clear:
		quest_manager.clear_quest(quest)
	elif mode == Mode.receive:
		quest_manager.receive_quest(quest)
	# 퀘스트 리스트 업데이트
	update_accept_panel()
	update_panel()

# 디버그용 처음씬으로 돌아가기
func go_main_scene():
	ViewManager.load_world("TestCountry","ChoicePanel","TestCountry")
