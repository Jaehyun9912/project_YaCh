
class Condition:
	var tag: String
	var shouldOn: bool

	func _init(_tag: String, _shouldOn: bool):
		tag = _tag
		shouldOn = _shouldOn


extends RefCounted
class_name Quest

var id : String

var conditions = {}

func is_met(player: Node) -> bool : 
	# check every condition
	for condition in conditions:
		if TagManager.has_tag(condition.tag, player) != condition.shouldOn :
			# some condition conflict
			return false;
	
	# meet all conditions
	return true;
