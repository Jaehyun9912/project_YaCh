class_name ITagProvider

signal on_tag_requested(node: Node, tag: String, count: int)

func _init(tagService: TagService):
	on_tag_requested.connect(tagService.change_tag)
