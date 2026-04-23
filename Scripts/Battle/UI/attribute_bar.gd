class_name AttributeBar extends Control

var max_value: float = 100.0
var total_value: float = 0.0

# 임계점 도달한 속성
var threshold_exceeded: String = ""

# 재귀 방지 플래그
var _is_updating: bool = false

# 속성 수치가 임계점을 넘었을 때
signal attribute_threshold_exceeded(attribute_name: String, active_type: AttributeData.Overdrive.OverdriveType)
# 속성 수치가 임계점 아래로 감소하였을 때 (KEEP에서 버프 제거용)
signal attribute_threshold_recovered(attribute_name: String)

# [String] = [float, ColorRect]
# 속성의 수치와 해당하는 사각형 반환 
var type: Dictionary = {}

@onready var background_color: ColorRect = $ColorRect

# id에 해당하는 속성값을 가져옴 (없으면 0)
func get_element(id):
	if id in type:
		return type[id][0]
	else:
		return 0
	
func _ready():
	type = {}
	total_value = 0
	threshold_exceeded = ""
	if background_color:
		background_color.color = Color(0, 0, 0, 0)
	
	if not attribute_threshold_exceeded.is_connected(_on_threshold_exceeded):
		attribute_threshold_exceeded.connect(_on_threshold_exceeded)
	if not attribute_threshold_recovered.is_connected(_on_threshold_recovered):
		attribute_threshold_recovered.connect(_on_threshold_recovered)

# max_value 및 none 설정 
func init(init_max: float):
	if init_max <= 0:
		init_max = 100.0
	max_value = init_max
	
	var container = $VBoxContainer
	if container:
		for child in container.get_children():
			child.queue_free()
		
	type = {}
	total_value = 0
	
	_is_updating = true 
	_process_value_change(AttributeInformation.NONE_ATTRIBUTE, init_max)
	update_value()
	_is_updating = false

# 외부에서 호출하는 속성 추가 함수
func add_value(attribute_name: String, amount: float):
	if _is_updating:
		_process_value_change(attribute_name, amount)
		return
		
	_is_updating = true
	_process_value_change(attribute_name, amount)
	_check_thresholds(attribute_name)
	update_value()
	_is_updating = false

# 실제 수치 계산 및 밸런싱 로직 (재귀 없음)
func _process_value_change(attribute_name: String, amount: float):
	if not attribute_name in type:
		add_new_bar(attribute_name, 0)
	
	var old_val = type[attribute_name][0]
	var new_val = clamp(old_val + amount, 0, max_value)
	var actual_diff = new_val - old_val
	
	type[attribute_name][0] = new_val
	total_value += actual_diff
	
	# 밸런싱 (총합이 max_value를 유지하도록 조정)
	_balance_total(attribute_name)

# 총합을 max_value로 맞추는 로직
func _balance_total(target_attribute: String):
	var diff = total_value - max_value
	if abs(diff) < 0.001: return
	
	if diff > 0: # 초과 시 다른 속성 깎기
		if target_attribute != AttributeInformation.NONE_ATTRIBUTE and AttributeInformation.NONE_ATTRIBUTE in type:
			var none_val = type[AttributeInformation.NONE_ATTRIBUTE][0]
			var reduce = min(none_val, diff)
			type[AttributeInformation.NONE_ATTRIBUTE][0] -= reduce
			diff -= reduce
			total_value -= reduce
			
		var safety_count = 0
		while diff > 0.001 and safety_count < 10:
			safety_count += 1
			var min_attr = find_min(target_attribute)
			if min_attr == "" or type[min_attr][0] <= 0: break
			
			var reduce = min(type[min_attr][0], diff)
			type[min_attr][0] -= reduce
			diff -= reduce
			total_value -= reduce
			
	elif diff < 0: # 부족 시 NONE_ATTRIBUTE로 채우기
		if not AttributeInformation.NONE_ATTRIBUTE in type:
			add_new_bar(AttributeInformation.NONE_ATTRIBUTE, 0)
			
		var fill = abs(diff)
		type[AttributeInformation.NONE_ATTRIBUTE][0] += fill
		total_value += fill

# 임계점 체크 로직 분리
func _check_thresholds(attribute_name: String):
	if attribute_name == AttributeInformation.NONE_ATTRIBUTE: return

	var attr_info = AttributeInformation.get_attribute(attribute_name)
	if attr_info == null or attr_info.overdrive == null: return
	
	var overdrive = attr_info.overdrive
	var current_val = type[attribute_name][0]
	var threshold_val = max_value * overdrive.threshold
	
	match overdrive.type:
		AttributeData.Overdrive.OverdriveType.KEEP:
			if current_val >= threshold_val:
				if threshold_exceeded != attribute_name:
					attribute_threshold_exceeded.emit(attribute_name, overdrive.type)
			elif attribute_name == threshold_exceeded:
				var end_threshold = max_value * overdrive.threshold_end
				if current_val < end_threshold:
					attribute_threshold_recovered.emit(attribute_name)
					
		AttributeData.Overdrive.OverdriveType.EXPLODE:
			if current_val >= threshold_val:
				attribute_threshold_exceeded.emit(attribute_name, overdrive.type)

func remove_value(attribute_name: String, amount: float):
	add_value(attribute_name, -amount)

func reset_value(attribute_name: String):
	if attribute_name in type:
		var current = type[attribute_name][0]
		if current > 0:
			remove_value(attribute_name, current)

func update_value():
	if max_value <= 0: return
	
	for attribute_name in type:
		var bar_data = type[attribute_name]
		var val = bar_data[0]
		var bar = bar_data[1]
		
		if is_instance_valid(bar):
			var ratio = val / max_value
			bar.visible = (val > 0.001)
			bar.size_flags_stretch_ratio = ratio
			if bar.visible and bar.size_flags_stretch_ratio < 0.001:
				bar.size_flags_stretch_ratio = 0.001

func add_new_bar(attribute_name: String, amount: float):
	var attribute_info = AttributeInformation.get_attribute(attribute_name)
	
	var container = $VBoxContainer
	if not container: return

	var newBar = ColorRect.new()
	newBar.name = attribute_name
	container.add_child(newBar)
	
	if attribute_info != null:
		newBar.color = attribute_info.display.color
	else:
		newBar.color = Color.GRAY
		
	newBar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	newBar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	newBar.visible = (amount > 0.001)
	
	type[attribute_name] = [amount, newBar]

func find_min(skip: String) -> String:
	var best_attr = ""
	var min_val = INF
	
	for attr in type:
		if attr == skip or attr == AttributeInformation.NONE_ATTRIBUTE: continue
		if type[attr][0] > 0.001 and type[attr][0] < min_val:
			min_val = type[attr][0]
			best_attr = attr
			
	return best_attr

func _on_threshold_exceeded(attribute_name: String, active_type: AttributeData.Overdrive.OverdriveType):
	match active_type:
		AttributeData.Overdrive.OverdriveType.EXPLODE:
			reset_value(attribute_name)

		AttributeData.Overdrive.OverdriveType.KEEP:
			threshold_exceeded = attribute_name
			var attr_info = AttributeInformation.get_attribute(attribute_name)
			if attr_info == null: return
			var co = attr_info.display.color
			co = co.darkened(0.5)
			co.a = 0.5
			if background_color:
				background_color.color = co

func _on_threshold_recovered(attribute_name: String):
	if threshold_exceeded == attribute_name:
		threshold_exceeded = ""
		if background_color:
			background_color.color = Color(0, 0, 0, 0)
