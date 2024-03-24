extends Area3D

var address
var view_manager = null
# Called when the node enters the scene tree for the first time.
func _ready():
	view_manager = get_node("/root/Node")
	address = get_meta("name")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("Area3D가 클릭되었습니다!" + address)
		print(view_manager)
		view_manager.load_world(address, "3Button")
