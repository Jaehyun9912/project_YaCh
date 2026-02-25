class_name MapLocation
extends Node2D

# 맵에 위치하는 지역 데이터
var _location_data: Dictionary

# 맵 상하좌우에 있는 지역 이름
var left:
	get:
		if _location_data.has("Left"):
			return _location_data["Left"]
		return location
var right:
	get:
		if _location_data.has("Right"):
			return _location_data["Right"]
		return location
var up:
	get:
		if _location_data.has("Up"):
			return _location_data["Up"]
		return location
var down:
	get:
		if _location_data.has("Down"):
			return _location_data["Down"]
		return location

# 해당 지역 이름
var location:
	get:
		return _location_data["Location"]


# 각 지역을 맵에 직접 배치
func set_location(data):
	_location_data = data
	position.x = data["xPos"]
	position.y = data["yPos"]

# 해당 월드로 이동
func enter_world():
	ViewManager.load_world(location, "ChoicePanel")
	print("AreaClicked : ", location)

# 지역 클릭 시 이동함수
func _on_location_clicked(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		enter_world()
