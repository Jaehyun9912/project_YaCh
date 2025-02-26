extends Control

# [String] = [float, ColorRect]
# 속성의 수치와 해당하는 사각형 반환 
var type : Dictionary

func get_element(id):
	if id in type.keys():
		return type[id][0]
	else:
		return 0

# (임시) 속성의 색을 정해주는 사전 
@export var attribute_color : Dictionary

var max_value : float
var total_value : float
	
# max_value 및 none 설정 
func init(max):
	max_value = max
	add_value("none", max)
	
	update_value()

# 기존 속성 업데이트 또는 새로운 속성 추가 
func add_value(name : String, amount : float):
	# 기존 속성에 값 추가 (0 ~ max_value로 범위 고정) 
	if name in type:
		type[name][0] += amount
		
		# 0이 되면 속성 제거
		if type[name][0] <= 0:
			amount -= type[name][0]
			type[name][0] = 0
			type[name][1].queue_free()
			type.erase(name)
		elif type[name][0] > max_value:
			amount -= type[name][0] - max_value
			type[name][0] = max_value
	# 새로운 속성일 경우 새롭게 추가 
	else:
		add_new_bar(name, amount)
		
	# 만약 총합이 최대치보다 많아질 경우 
	total_value += amount
	#print("total:", total_value) 
	if total_value > max_value:
		# 빈 속성을 우선적으로 제거 
		if "none" in type and type["none"][0] > 0:
			add_value("none", max_value - total_value)
		# 빈 속성이 없을 경우 가장 작은 속성을 제거
		else:
			var minimum = find_min(name)
			add_value(minimum, max_value - total_value)
			
	update_value()	

func remove_value(name : String, amount : float):
	add_value(name, -amount)

# 모든 속성 바를 자신이 차지하는 값만큼 비율을 계산해 막대 길이 조정 
func update_value():
	for name in type:
		#print(name, ":", type[name][0] / max_value)
		type[name][1].size_flags_stretch_ratio = type[name][0] / max_value

# 새로운 속성 바를 추가하기 
func add_new_bar(name : String, amount : float):
	var newBar = ColorRect.new()
	
	# ColorRect를 생성해서 설정.
	$VBoxContainer.add_child(newBar)
	#newBar.color = attribute_color[name]
	var new_color = $AttributeInfomation.get_attribute_color(name)
	if new_color == null:
		printerr("속성 이름 잘못됨!")
		return
	newBar.color = new_color
	newBar.size_flags_vertical = Control.SIZE_EXPAND_FILL

	type[name] = [amount, newBar]

# 속성 중 가장 작은 속성 추출 (0이거나 인자로 주어진 속성 제외) 
func find_min(skip : String) -> String:
	if (type.size() == 1): 
		return type.keys[0]
	
	# 주어진 속성을 제외한 최소값 구하기.
	var n = "none"
	var min = max_value + 10
	for i in type:
		if i == skip or type[i][0] == 0: continue
		if type[i][0] < min:
			min = type[i][0]
			n = i
	return n
