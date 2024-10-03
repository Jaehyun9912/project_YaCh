extends Node

# Connect to signal to 
func connect_to_signal(target: Node, name: String, listen_node : Node, callback: Callable) :
	if target.has_signal(name) :
		target.connect(name, callback)
	else :
		print_debug("SIGNAL NOT EXIST : " + name)
