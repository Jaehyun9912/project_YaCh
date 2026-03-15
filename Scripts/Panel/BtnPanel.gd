class_name BtnPanel
extends ColorRect

var btn_container:
	get:
		return $ScrollContainer/VBoxContainer

# ChatPanel에서 사용중
func create_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn_container.add_child(button)
	return button

func clear_buttons() -> void:
	for i in btn_container.get_children():
		i.queue_free()