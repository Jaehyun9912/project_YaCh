class_name MapLocation
extends Control

var left : MapLocation
var right : MapLocation
var up : MapLocation
var down : MapLocation

var location : String
func set_location(data):
	location = data["Location"]
	position.x = data["Position"]["x"]
	position.y = data["Position"]["y"]

# 해당 월드로 이동
func move_to_location():
	#ViewManager.load_world(location,"기본 패널")
	pass
