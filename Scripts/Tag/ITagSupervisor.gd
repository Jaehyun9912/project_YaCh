class_name ITagSupervisor

signal on_tag_responsed(node, tag, count)

var tagService

func _init(tagSystem: TagService):
	tagService = tagSystem
	tagService.on_tag_changed.connect(work)

func _exit_tree():
	tagService.on_tag_changed.disconnect(work)

func work(node: Node, tag: String, count: int):
	on_tag_responsed.emit(node, tag, count)
	pass