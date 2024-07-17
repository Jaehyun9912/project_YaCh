extends Node

const WORLD_PATH = "res://Worlds/"
const PANEL_PATH = "res://InteractPanels/"

var world_instance: Node = null
var current_panel: Control = null

# Called when the node enters the scene tree for the first time.
func _ready():	
	world_instance = get_child(0)
	current_panel = get_node("Interact").get_child(0)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):


func load_world(world_name: String, panel_name: String = "3Button") -> void :
	# remove current world instance
	if world_instance != null:
		world_instance.queue_free()
		
	# load new world
	var new_world = load(WORLD_PATH + world_name + ".tscn")
	print(WORLD_PATH + world_name)
	world_instance = new_world.instantiate()
	add_child(world_instance)
	
	# remove current Panel
	if current_panel != null:
		current_panel.queue_free()
		
	# load new Panel
	var new_panel = load(PANEL_PATH + panel_name + ".tscn")
	print(PANEL_PATH + panel_name)
	current_panel = new_panel.instantiate()
	get_node("Interact").add_child(current_panel)
