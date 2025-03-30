extends Node

@onready var buttons = get_tree().get_nodes_in_group("skill_buttons")
@onready var button_img = $ButtonImage
@onready var cancel_area = $ButtonCancelArea

var selected_button_index = -1

func _ready():
	# 버튼에 시그널 연결 
	for i in len(buttons):
		var btn = buttons[i] as RoundButton
		var index = i
		
		btn.button_down.connect(on_skillbutton_down.bind(btn, index))
		btn.button_up.connect(on_skillbutton_up)
	
func _process(delta):
	if selected_button_index != -1:
		button_img.global_position = get_viewport().get_mouse_position() - button_img.pivot_offset
	
func set_all_buttons(OnOff):
	for i in buttons:
		i.disabled = !OnOff
	
func on_skillbutton_down(btn, index):
	set_all_buttons(false)
	btn.disabled = false
	button_img.visible = true
	
	cancel_area.visible = true
	cancel_area.position = btn.position
	var tween = get_tree().create_tween()
	tween.tween_property(cancel_area, "scale", Vector2(4.5, 4.5), 0.1)
	
	selected_button_index = index
	
func on_skillbutton_up():
	set_all_buttons(true)
	button_img.visible = false
	cancel_area.visible = false
	cancel_area.scale = Vector2(1, 1)
	
	selected_button_index = -1
	




func _on_button_cancel_area_mouse_entered():
	pass # Replace with function body.


func _on_button_cancel_area_mouse_exited():
	pass # Replace with function body.
