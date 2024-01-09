extends Node3D

var current_location

# Called when the node enters the scene tree for the first time.
func _ready():	
	current_location = get_meta("location")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _open_location(address):
	print("새 월드 로드" + address)
	current_location.queue_free()
