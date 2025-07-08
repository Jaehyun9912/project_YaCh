extends ColorRect

var point
var bar: ColorRect

# 최초 정보 입력 
func init(max_point, text, bar_color):
	bar = $ColorRect
	bar.color = bar_color
	$Label.text = text
	point = max_point
	
# 행동력 최대치 수정
func set_point(new_point):
	point = new_point
	set_ratio(-1)
	
# 현재 행동력 입력받아 바 수정 
func set_ratio(current):
	if current > point or current < 0: current = point
	bar.scale.x = float(current) / point
	
