@tool
extends Control

@export var package_title: Label
@export var file_system : DE_FileSystem
@export var editor : DE_Editor

var package_path = "res://Data"

# Called when the node enters the scene tree for the first time.
func _ready():
	# 패키지 경로에 있는 파일들을 트리에 표시합니다.
	load_package(package_path)

func load_package(path: String):
	# 패키지 경로를 업데이트하고 트리를 새로 고칩니다.
	package_path = path
	file_system.refresh_tree(package_path)
	package_title.text = "Package: " + package_path
	print("Package loaded: ", package_path)

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_visible_in_tree():
            # 탭이 활성화될 때 레이아웃 재계산 강제 호출
			queue_redraw()

func _on_file_system_item_selected():
	var selected_item = file_system.get_selected()
	var path = selected_item.get_metadata(0) # 메타데이터에서 경로 가져오기

	if path:
		var data = editor.parse_json(path)
		print("Selected file: ", path)
		print("Data: ", data)
	else:
		print("선택된 항목에 경로 정보가 없습니다.")
