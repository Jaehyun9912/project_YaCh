class_name MapLocation
extends Node2D


var left : MapLocation
var right : MapLocation
var up : MapLocation
var down : MapLocation

var location : String
func set_location(data):
	location = data["Location"]
	position.x = data["xPos"]
	position.y = data["yPos"]

# 해당 월드로 이동
func enter_world(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		ViewManager.load_world(location)
		print("AreaClicked : ",location)
