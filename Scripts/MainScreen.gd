extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var side = ViewManager.current_scene.get_node("SidePanelLayer")
	side.hide()
	pass # Replace with function body.



func show_side_panel():
	var side = ViewManager.current_scene.get_node("SidePanelLayer")
	side.show()
