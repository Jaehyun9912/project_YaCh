extends Node


@export var conditions: Array[String]
@export var add_tags: Array[String]

var tagProvider: ITagProvider

func _init(tagService: TagService):
	tagProvider = ITagProvider.new(tagService)
	

# 태그 확인 후 태그 붙이기
func condition_process() -> bool:
	for i in conditions:
		if !Quest.check_condition(i):
			return false
	for i in add_tags:
		tagProvider.on_tag_requested.emit(PlayerData, i, 1)
		
	return true


# 물체와 상호작용
func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("TagAdderClicked")
		condition_process()
