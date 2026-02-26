extends RefCounted
class_name ITagSupervisor

signal on_tag_responsed(node: Node)

var _target: Node

var tag_list: Array[String]

var tag_service

var is_working: bool

# 태그가 변화할 때까지 감시
func _init(target: Node, list: Array[String]):
	_target = target
	tag_list = list
	tag_service = TagService
	if tag_service.has_signal("on_tag_changed"):
		tag_service.on_tag_changed.connect(check_tag)

# 변화한 태그가 조건에 맞는지 확인
func check_tag(node: Node):
	if node != _target:
		return
	if is_working:
		return
	
	is_working = true
	var _is_conform = tag_list.all(func(tag): return tag_service.has_tag(node, tag))

	if _is_conform:
		print("Condition Conformed")
		on_tag_responsed.emit(node)

	is_working = false
	
	pass
