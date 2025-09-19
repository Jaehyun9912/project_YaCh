class_name TagSupervisor

signal on_tag_responsed(node, tag, count)

var tag_service

func _init(tagSystem):
	tag_service = tagSystem
	if tag_service.has_signal("on_tag_changed"):
		tag_service.on_tag_changed.connect(work)

func _exit_tree():
	if tag_service.has_signal("on_tag_changed"):
		tag_service.on_tag_changed.disconnect(work)

func work(node: Node, tag: String, count: int):
	on_tag_responsed.emit(node, tag, count)
	pass
