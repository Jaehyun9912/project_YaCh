extends Node


@export var conditions: Array[String]
@export var add_tags: Array[String]


# 태그 확인 후 태그 붙이기
func condition_process() -> bool:
	for i in conditions:
		if !Quest.check_condition(i):
			return false
	for i in add_tags:
		TagManager.add_tag_tree(PlayerData, i)
	return true


# 물체와 상호작용
func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("TagAdderClicked")
		condition_process()
