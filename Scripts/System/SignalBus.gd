extends Node


var _tagService: TagService
var tagService:
	get:
		if _tagService == null:
			tagService = TagService.new()
		return _tagService


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
