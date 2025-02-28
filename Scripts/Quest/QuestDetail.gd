extends Control

# 수주, 클리어 관련 버튼 이벤트
signal option_pressed(quest:Quest, mode: Mode)

signal any_button_pressed()

# 디테일 패널 모드 설정
enum Mode{
	RECEIVE, 
	PROCESS,
	CLEAR,
}

# 현재 모드
var curMode : Mode

# 현재 표시중인 퀘스트
var quest : Quest




# 해당 퀘스트에 대한 디테일 패널 표시 
func set_quest(get_quest : Quest, mode : Mode) -> void:
	quest = get_quest
	curMode = mode
	# 디테일 패널 정보 표시
	$"QuestDescription/Label".text = quest.title
	$"QuestDescription/RichTextLabel".text = quest.description
	# 모드에 따른 수주/클리어 버튼 활성화 여부 설정
	var option_panel = $"Btns/VBoxContainer/OptionPanel"
	if mode == Mode.PROCESS:
		option_panel.hide()
	else:
		option_panel.show()
	if mode == Mode.CLEAR:
		option_panel.get_child(0).text = "제출"
	elif mode == Mode.RECEIVE:
		option_panel.get_child(0).text = "수주"

# 버튼 선택 시 시그널 발생
func option_btn_pressed() -> void:
	option_pressed.emit(quest,curMode)

func button_pressed() -> void:
	any_button_pressed.emit()
