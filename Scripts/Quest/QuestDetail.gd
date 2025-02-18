extends Control

var quest : Quest

# 디테일 패널 모드 설정
enum Mode{
	receive, process, clear
}
# 옵션 버튼이 눌렸을 때 이벤트
signal option_pressed(quest:Quest, mode: Mode)

var curMode :Mode

# 해당 퀘스트에 대한 디테일 패널 표시 
func set_quest(get_quest : Quest, mode : Mode):
	quest = get_quest
	
	curMode = mode
	#디테일 패널 활성화 및 설정
	$"QuestDescription/Label".text = quest.title
	$"QuestDescription/RichTextLabel".text = quest.description
	var option_panel = $"Btns/VBoxContainer/OptionPanel"
	if mode == Mode.process:
		option_panel.hide()
	else:
		option_panel.show()
	if mode == Mode.clear:
		option_panel.get_child(0).text = "제출"
	elif mode == Mode.receive:
		option_panel.get_child(0).text = "수주"


func option_btn_pressed():
	option_pressed.emit(quest,curMode)
