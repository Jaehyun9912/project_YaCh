extends Node

var _tag_service
func get_tag_service():
	if _tag_service == null:
		_tag_service = TagService.new()
	return _tag_service
