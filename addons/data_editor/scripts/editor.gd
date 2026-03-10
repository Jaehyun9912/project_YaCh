@tool
class_name DE_Editor extends Tree


func load_json_data(path: String) -> Dictionary:
	return parse_json(path)	

func parse_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()

		var json = JSON.new()
		var json_error = json.parse(json_text)
		if json_error == OK:
			return json.data
		else:
			print("JSON 파싱 오류: ", json.error_string())
	else:
		print("파일을 열 수 없습니다: ", path)
	
	return {} # 오류 시 빈 딕셔너리 반환