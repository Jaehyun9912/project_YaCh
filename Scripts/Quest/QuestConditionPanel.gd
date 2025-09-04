extends Control


var content: BagContent

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
		var s = ""
		for i in content.condition_list:
			if i.check:
				s += "[V] "
			else:
				s += "[] "
			s += i.condition + "\n"
		condition_box.text = s
