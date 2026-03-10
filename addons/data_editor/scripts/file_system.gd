@tool
class_name DE_FileSystem extends Tree

func refresh_tree(base_path: String):
	clear() # 기존 항목 싹 비우기
	
	# 1. 최상위 루트 생성
	var root = create_item()
	hide_root = true
	
	# 2. 재귀 함수 시작
	_scan_directory(base_path, root)

# 폴더를 파고들며 아이템을 추가하는 핵심 함수
func _scan_directory(path: String, parent_item: TreeItem):
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# . 이나 .. 로 시작하는 시스템 파일/폴더 제외
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
				
			var full_path = path + "/" + file_name
			
			if dir.current_is_dir():
				# --- [폴더인 경우] ---
				var dir_item = create_item(parent_item)
				dir_item.set_text(0, file_name)
				# 폴더 아이콘 설정 (에디터 내장 아이콘 활용)
				dir_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
				dir_item.set_selectable(0, false) # 폴더 자체는 데이터가 아니므로 선택 불가 설정 가능
				
				# 중요: 폴더 안을 다시 스캔 (재귀 호출)
				_scan_directory(full_path, dir_item)
				
			else:
				# --- [파일인 경우] ---
				if file_name.ends_with(".json"): # JSON 파일만 필터링
					var file_item = create_item(parent_item)
					file_item.set_text(0, file_name)
					# 파일 아이콘 설정
					file_item.set_icon(0, get_theme_icon("File", "EditorIcons"))
					# 나중에 클릭했을 때 파일을 열 수 있도록 메타데이터에 경로 저장
					file_item.set_metadata(0, full_path)
			
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("경로를 열 수 없습니다: ", path)