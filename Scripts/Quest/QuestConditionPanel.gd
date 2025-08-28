extends Control



var content : BagContent

var title:
	get:
		return $"ColorRect/Title"
var description:
	get:
		return $"ColorRect/Description"
var condition_box:
	get:
		return $"ColorRect/Conditions"


func set_panel(_content):
	content = _content
	title.text = content.get_title()
	description.text = content.get_description()
	if content is Quest:
		var list = content.get_quest_condition()
		var s : String
		for i in list:
			var complete = Quest.check_condition(i)
			if complete:
				s+= "[V] "
			else:
				s+="[] "
			s+= i+"\n"
		condition_box.text = s
	
	
	
