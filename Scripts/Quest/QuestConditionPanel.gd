extends Control


var quest : Quest

var title:
	get:
		return $"ColorRect/Title"
var description:
	get:
		return $"ColorRect/Description"
var condition_box:
	get:
		return $"ColorRect/VBoxContainer"


func set_panel(_quest):
	quest = _quest
	title.text = quest.title
	description.text = quest.description
	
	
	
