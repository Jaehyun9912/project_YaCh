extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	pass

func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("Area3D가 클릭되었습니다!")
