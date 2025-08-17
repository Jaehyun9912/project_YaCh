class_name CastingPanel extends Control

signal casting_end(is_succes: bool)

var twn = null

func _ready():
	visible = false

func set_casting_panel(text, time, is_button_visible, callback):
	visible = true
	$Label.text = text
	$Button.visible = is_button_visible
	
	casting_end.connect(callback)
	
	var progress = $ProgressBar as ProgressBar
	progress.value = 0
	
	twn = create_tween() as Tween
	twn.tween_property(progress, "value", 100, time)
	twn.finished.connect(_on_end_tween)
	
func _on_end_tween():
	print("tween End")
	twn = null
	casting_end.emit(true)
	
	for i in casting_end.get_connections():
		casting_end.disconnect(i.callable)
		
	visible = false
	

func _on_button_pressed():
	if twn is Tween:
		twn.kill()
		twn = null
	print("tween canceled")
	casting_end.emit(false)
	
	for i in casting_end.get_connections():
		casting_end.disconnect(i.callable)
		
	visible = false
