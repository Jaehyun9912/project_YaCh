extends Control

var quest : Quest

enum Mode{
	receive, process, clear
}
signal option_pressed(quest:Quest, mode: Mode)
var curMode :Mode

func set_quest(get_quest : Quest, mode : Mode):
	quest = get_quest
	show_quest_detail(mode)
	
func show_quest_detail(mode :Mode):
	curMode = mode
	show()
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
