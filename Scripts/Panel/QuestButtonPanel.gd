extends Control
class_name QuestButtonPanel

signal on_exit
# 수주, 클리어 관련 버튼 이벤트
signal option_pressed(quest, mode: Mode)

signal any_button_pressed()

# 디테일 패널 모드 설정
enum Mode{
	RECEIVE, 
	PROCESS,
	CLEAR,
}

@export var option_panel : Control
@export var option_button : Button
# 현재 모드
var curMode : Mode

# 현재 표시중인 퀘스트
var cur_quest

var info_panel

# 해당 퀘스트에 대한 디테일 패널 표시 
func set_quest(quest, mode : Mode) -> void:
	cur_quest = quest
	curMode = mode
	info_panel = ViewManager.push_panel("QuestInfoPanel",ViewManager.SCREEN.TOP) as QuestInfoPanel
	info_panel.set_quest_info(cur_quest)
	# 모드에 따른 수주/클리어 버튼 활성화 여부 설정
	if mode == Mode.PROCESS:
		option_panel.hide()
	else:
		option_panel.show()
		if mode == Mode.CLEAR:
			option_button.text = "제출"
		elif mode == Mode.RECEIVE:
			option_button.text = "수주"

# 버튼 선택 시 시그널 발생
func option_btn_pressed() -> void:
	option_pressed.emit(cur_quest,curMode)

func button_pressed() -> void:
	info_panel.on_exit.emit()
	on_exit.emit()
