extends Control
class_name PanelManager

var type : String;
var panelPos : String

var panelNode : Control

# Called when the node enters the scene tree for the first time.
func _ready():
	panelNode = get_node(panelPos)


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
