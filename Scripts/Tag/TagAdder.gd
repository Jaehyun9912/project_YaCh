extends Node


@export var conditions : Array[String]
@export var add_tags : Array[String]




# 태그 확인 후 태그 붙이기
func condition_process() -> bool:
	if Quest.condition_check(conditions):
		#모든 조건 충족
		for i in add_tags:
			TagManager.add_tag_tree(PlayerData,i)
		print(TagManager.get_tags(PlayerData))
		return true
	return false


# 물체와 상호작용
func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("TagAdderClicked")
		condition_process()


