extends Node
class_name TagSupervisor

signal on_tag_responsed(node: Node)

@export var tag_list: Array[String]

var tag_service

func _init():
	tag_service = DiContainer.get_tag_service()
	if tag_service.has_signal("on_tag_changed"):
		tag_service.on_tag_changed.connect(work)

func _exit_tree():
	if tag_service.has_signal("on_tag_changed"):
		tag_service.on_tag_changed.disconnect(work)

func work(node: Node):
	for i in tag_list:
		if !tag_service.has_tag(node, i):
			return
	print("Condition Conformed")
	if tag_service.has_signal("on_tag_changed"):
		tag_service.on_tag_changed.disconnect(work)
	on_tag_responsed.emit(node)
	
	pass
