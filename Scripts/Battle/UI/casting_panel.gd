class_name CastingPanel extends Control

var callback_func: Callable
var battle_panel: BattlePanel

enum CastingButtonType {
	Counter,
	Parrying
}

var twn = null

func _ready():
	visible = false

func set_casting_panel(text, time, button_type: CastingButtonType, callback: Callable):
	visible = true
	$Label.text = text

	_set_button_by_type(button_type)

	callback_func = callback
	
	var progress = $ProgressBar as ProgressBar
	progress.value = 0
	
	twn = create_tween() as Tween
	twn.tween_property(progress, "value", 100, time)
	twn.finished.connect(_on_end_tween)
	
func _on_end_tween():
	#print("tween End")
	twn = null
	callback_func.call(true)
		
	visible = false

func _on_button_pressed():
	if twn is Tween:
		twn.kill()
		twn = null
	#print("tween canceled")
	callback_func.call(false)
		
	visible = false

func _set_button_by_type(button_type: CastingButtonType):
	var useable_skills
	match button_type:
		CastingButtonType.Counter:
			useable_skills = SkillManager.get_useable_special_skills(SkillManager.SpecialSkillType.COUNTER, battle_panel.current_charcter.point, battle_panel.manager.attribute_bar)
		CastingButtonType.Parrying:
			useable_skills = SkillManager.get_useable_special_skills(SkillManager.SpecialSkillType.PARRYING, battle_panel.current_charcter.point, battle_panel.manager.attribute_bar)

	for i in useable_skills:
		pass
		