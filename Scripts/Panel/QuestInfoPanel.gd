extends Node
class_name QuestInfoPanel

signal on_exit

@export var title : Label
@export var description : RichTextLabel


func set_quest_info(quest):
	title.text = quest["title"]
	description.text = quest["description"]
