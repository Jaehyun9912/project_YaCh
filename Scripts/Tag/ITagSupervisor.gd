class_name ITagSupervisor

signal on_tag_responsed(node: Node)

var tag_list: Array[String]

var tag_service

var flag : bool

func _init(list : Array[String]):
	tag_list = list
	tag_service = TagService
	if tag_service.has_signal("on_tag_changed"):
		tag_service.on_tag_changed.connect(work)

func work(node: Node):
	if !flag:
		flag = true
		for i in tag_list:
			if !tag_service.has_tag(node, i):
				return
		print("Condition Conformed")
		on_tag_responsed.emit(node)
		flag = false
	
	pass

