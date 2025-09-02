class_name CastingPanel extends Control

var call: Callable

var twn = null

func _ready():
	visible = false

func set_casting_panel(text, time, is_button_visible: bool, callback: Callable):
	visible = true
	$Label.text = text
	$Button.visible = is_button_visible
	
	call = callback
	
	var progress = $ProgressBar as ProgressBar
	progress.value = 0
	
	twn = create_tween() as Tween
	twn.tween_property(progress, "value", 100, time)
	twn.finished.connect(_on_end_tween)
	
func _on_end_tween():
	print("tween End")
	twn = null
	call.call(true)
		
	visible = false

func _on_button_pressed():
	if twn is Tween:
		twn.kill()
		twn = null
	print("tween canceled")
	call.call(false)
		
	visible = false
