extends Control

var container:
	get:
		return $"QuestList/VBoxContainer"

enum Mode{process,receive,clear}
var mode = Mode.process

signal option_pressed
var select_quest : Quest
#퀘스트 상세내용 및 옵션 제공
func show_quest_detail():
	$"ColorRect2".show()
	$"ColorRect2/Label".text = select_quest.title
	$"ColorRect2/RichTextLabel".text = select_quest.description
	print(mode)
	print(select_quest.id)
	if mode == Mode.receive:
		$"ColorRect2/OptionBtn".show()
	elif mode == Mode.clear:
		$"ColorRect2/OptionBtn".show()

func set_select_quest(quest : Quest):
	select_quest = quest as Quest


#버튼 1개와 퀘스트 연결
func set_quest_button(quest : Quest):
	var button = Button.new()
	button.text = quest.title
	button.pressed.connect(set_select_quest.bind(quest))
	button.pressed.connect(show_quest_detail)
	container.add_child(button)

func set_quest_buttons(list : Array[Quest]):
	print(mode)
	if mode == Mode.process:
		$QuestList/Label.text = "수주중인 퀘스트"
	elif mode == Mode.clear:
		$QuestList/Label.text = "제출 가능 퀘스트"
	else:
		$QuestList/Label.text = "수주 가능 퀘스트"
	for i in container.get_children():
		i.queue_free()
	for i in list:
		set_quest_button(i)

func close_panel():
	ViewManager.erase_panel(self)

func option_button():
	option_pressed.emit(select_quest)
	option_pressed.emit()
	print("Option_pressed")
