extends ProgressBar

signal end_anim
var fill

var lab: Label
var ls: LabelSettings

# 최초 정보 입력 
func init(max_point, text, bar_color):
	fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.bg_color.a = 0
	add_theme_stylebox_override("fill", fill)
	
	lab = $Label
	
	lab.text = text
	max_value = max_point
	value = max_point
	
	ls = lab.label_settings
	if ls == null:
		ls = LabelSettings.new()
	ls = ls.duplicate()
	
func set_outline(onoff: bool, is_counter: bool):
	var s = 0
	var co = Color.WHITE
	
	if onoff: s = 10
	if is_counter: co = Color.RED

	ls.outline_size = s
	ls.outline_color = co
	lab.label_settings = ls
	lab.queue_redraw()
	
# 행동력 최대치 수정
func set_max_point(new_point):
	max_value = new_point
	value = 0
	set_point(new_point)
	
# 현재 행동력 입력받아 바 수정 
func set_point(current):
	print("change point ", current, ", max: ", max_value)
	if current > max_value or current < 0: 
		current = max_value
	
	var tween = create_tween()
	tween.tween_property(self, "value", current, 0.5)
	
	await tween.finished
	end_anim.emit()
	
