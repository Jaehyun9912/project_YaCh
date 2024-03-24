extends Node

const WORLD_PATH = "res://Worlds/"
const PANEL_PATH = "res://InteractPanels/"

var world_instance: Node = null
var current_panel: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():	
	world_instance = get_child(0)
	current_panel = "3Button"
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func load_world(world_path: String, panel_path: String = "3Button") -> void :
	# remove current world instance
	if world_instance != null:
		world_instance.queue_free()
		
	# load new world
	var world_scene = load(WORLD_PATH + world_path + ".tscn")
	print(WORLD_PATH + world_path)
	world_instance = world_scene.instantiate()
	add_child(world_instance)
	
	# load new Panel
	current_panel = panel_path
