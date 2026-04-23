class_name MapLocation
extends Node2D

var point_data: MapData.Point

var up: MapLocation
var down: MapLocation
var left: MapLocation
var right: MapLocation

var location: String:
	get: return point_data.id if point_data else ""

var display_name: String:
	get: return point_data.display_name if point_data else ""

func set_location(data: MapData.Point) -> void:
	point_data = data
	position = Vector2(data.position.x, data.position.y)

# 해당 월드로 이동
func enter_world():
	ViewManager.load_world(location, "ChoicePanel")
	print("AreaClicked : ", location)

# 지역 클릭 시 이동함수
func _on_location_clicked(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		enter_world()
