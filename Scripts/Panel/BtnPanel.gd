class_name BtnPanel
extends ColorRect

var btn_container:
	get:
		return $ScrollContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func create_button(text : String) -> Button:
	var button = Button.new()
	button.text = text
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	print(button.size_flags_vertical)
	btn_container.add_child(button)
	return button

func clear_buttons() -> void:
	for i in btn_container.get_children():
		i.queue_free()
		
