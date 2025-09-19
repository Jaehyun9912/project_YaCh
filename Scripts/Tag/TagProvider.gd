extends Node


@export var conditions: Array[String]
@export var add_tags: Array[String]

var tag_service

func _init(_tag_service):
	tag_service = _tag_service
	
	
# 태그 확인 후 태그 붙이기
func condition_process() -> bool:
	for i in add_tags:
		#tag_service.on_tag_requested.emit(PlayerData, i, 1)
		pass
	return true


# 물체와 상호작용
func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("TagAdderClicked")
		condition_process()
