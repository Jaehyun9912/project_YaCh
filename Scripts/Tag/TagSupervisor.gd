extends Node
class_name TagSupervisor

signal on_tag_responsed(node: Node)

@export var tag_list: Array[String]

var tag_service

func _ready():
	tag_service = ITagSupervisor.new(PlayerData, tag_list)
	tag_service.on_tag_responsed.connect(work)
	tag_service.check_tag(PlayerData)

func work(node: Node):
	on_tag_responsed.emit(node)
	pass
