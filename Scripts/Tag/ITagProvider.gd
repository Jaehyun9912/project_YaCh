class_name ITagProvider

signal on_tag_requested(node: Node, tag: String, count: int)

var tag_list: Array[String]

var tag_service

func _init(list : Array[String]):
	tag_list = list
	tag_service = TagService
	if tag_service.has_method("change_tag_tree"):
		on_tag_requested.connect(tag_service.change_tag_tree)

	
func work(node: Node):
	for i in tag_list:
		on_tag_requested.emit(node, i, 1)
		print("Tag Requested")
	pass
