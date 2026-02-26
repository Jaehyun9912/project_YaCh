extends Node
class_name TagProvider

signal on_tag_requested(node: Node, tag: String, count: int)

@export var tag_list: Array[String]

var tag_provider

func _ready():
	tag_provider = ITagProvider.new(tag_list)
	tag_provider.on_tag_requested.connect(func(node, tag, count):
		on_tag_requested.emit(node, tag, count))

	
func work(node: Node):
	tag_provider.work(node)
	pass
