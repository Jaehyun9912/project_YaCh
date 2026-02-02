class_name AttributeBar extends Control

# 속성 임계점 도달 시 동작 방식
enum ThresholdActiveType {
	# 광역 효과, 속성치 리셋
	EXPLODE,
	# 전체 버프, 속성치 유지
	KEEP,
}

var max_value: float
var total_value: float

# 임계점 도달한 속성
var threshold_exceeded: String

# 속성 수치가 임계점을 넘었을 때
signal attribute_threshold_exceeded(attribute_name: String, active_type: ThresholdActiveType)
# 속성 수치가 임계점 아래로 감소하였을 때 (KEEP에서 버프 제거용)
signal attribute_threshold_recovered(attribute_name: String)

# [String] = [float, ColorRect]
# 속성의 수치와 해당하는 사각형 반환 
var type: Dictionary

var background_color: ColorRect

# id에 해당하는 속성값을 가져옴 (없으면 0)
func get_element(id):
	if id in type.keys():
		return type[id][0]
	else:
		return 0
	
func _ready():
	type = {}
	total_value = 0
	threshold_exceeded = ""
	background_color = $ColorRect as ColorRect
	background_color.color = Color(0, 0, 0, 0)
	
	attribute_threshold_exceeded.connect(_on_threshold_exceeded)
	attribute_threshold_recovered.connect(_on_threshold_recovered)

# max_value 및 none 설정 
func init(init_max: float):
	max_value = init_max
	add_value(AttributeInformation.NONE_ATTRIBUTE, init_max)
	update_value()

# 기존 속성 업데이트 또는 새로운 속성 추가 
func add_value(attribute_name: String, amount: float):
	# 기존 속성에 값 추가 (0 ~ max_value로 범위 고정)
	if attribute_name in type:
		type[attribute_name][0] += amount

		# 0이 되면 속성 제거
		if type[attribute_name][0] <= 0:
			amount -= type[attribute_name][0]
			type[attribute_name][0] = 0
			type[attribute_name][1].visible = false
		elif type[attribute_name][0] > max_value:
			amount -= type[attribute_name][0] - max_value
			type[attribute_name][0] = max_value
			type[attribute_name][1].visible = true
		else:
			type[attribute_name][1].visible = true
	# 새로운 속성일 경우 새롭게 추가 
	else:
		add_new_bar(attribute_name, amount)


	# 만약 총합이 최대치보다 많아질 경우
	total_value += amount
	#print("total:", total_value) 
	
	if amount > 0 and total_value > max_value:
        # 빈 속성을 우선적으로 제거 
		if AttributeInformation.NONE_ATTRIBUTE in type and type[AttributeInformation.NONE_ATTRIBUTE][0] > 0:
			var reduce = min(type[AttributeInformation.NONE_ATTRIBUTE][0], total_value - max_value)
			type[AttributeInformation.NONE_ATTRIBUTE][0] -= reduce
			total_value -= reduce
			if type[AttributeInformation.NONE_ATTRIBUTE][0] <= 0:
				type[AttributeInformation.NONE_ATTRIBUTE][1].visible = false
		
		# 빈 속성이 없거나 부족해서 여전히 넘칠 경우 가장 작은 속성을 제거
		if total_value > max_value:
			var minimum = find_min(attribute_name)
			add_value(minimum, max_value - total_value)	

	# 2. 언더플로우 처리 (값이 부족할 때 -> None으로 채움)
	# 특정 속성을 깎았는데(amount < 0) 전체 합이 max_value보다 작아졌다면, 그만큼 None을 채워야 함
	elif total_value < max_value:
		# None 속성이 없으면 생성
		if not AttributeInformation.NONE_ATTRIBUTE in type:
			add_new_bar(AttributeInformation.NONE_ATTRIBUTE, 0)
			
		# 부족한 만큼 None 추가
		var fill_amount = max_value - total_value
		type[AttributeInformation.NONE_ATTRIBUTE][0] += fill_amount
		type[AttributeInformation.NONE_ATTRIBUTE][1].visible = true
		total_value += fill_amount

	update_value()

	# 임계점 도달 확인
	var overdrive = AttributeInformation.get_attribute(attribute_name).get("overdrive", null)
	if overdrive == null:
		return

	var threshold_value = max_value * overdrive.get("threshold", 2)
	var threshold_type = ThresholdActiveType.get(overdrive.get("type", "EXPLODE").to_upper())

	# 유형별 처리
	match threshold_type:
		ThresholdActiveType.KEEP:
			# 임계점 넘기면
			if threshold_value <= type[attribute_name][0]:
				attribute_threshold_exceeded.emit(attribute_name, threshold_type)
			var threshold_end = max_value * overdrive.get("threshold_end", threshold_value)
			if attribute_name == threshold_exceeded and threshold_end > type[attribute_name][0]:
				# 임계점 아래로 내려갔을 때
				attribute_threshold_recovered.emit(attribute_name)

		ThresholdActiveType.EXPLODE:
			# 임계점 넘기면
			if threshold_value <= type[attribute_name][0]:
				attribute_threshold_exceeded.emit(attribute_name, threshold_type)

		_:
			printerr("Unknown ThresholdActiveType:", threshold_type)
			return
			

func remove_value(attribute_name: String, amount: float):
	add_value(attribute_name, -amount)

# 속성 수치를 0으로 초기화
func reset_value(attribute_name: String):
	var current = get_element(attribute_name)
	if current > 0:
		remove_value(attribute_name, current)


# 모든 속성 바를 자신이 차지하는 값만큼 비율을 계산해 막대 길이 조정 
func update_value():
	for attribute_name in type:
		if type[attribute_name][1].visible == false:
			continue
		#print(name, ":", type[name][0] / max_value)
		type[attribute_name][1].size_flags_stretch_ratio = type[attribute_name][0] / max_value

# 새로운 속성 바를 추가하기 
func add_new_bar(attribute_name: String, amount: float):
	var newBar = ColorRect.new()
	
	# ColorRect를 생성해서 설정.
	$VBoxContainer.add_child(newBar)
	#newBar.color = attribute_color[attribute_name]
	var new_color = AttributeInformation.get_attribute_color(attribute_name)
	if new_color == null:
		printerr("속성 이름 잘못됨!")
		return
	newBar.color = new_color
	newBar.size_flags_vertical = Control.SIZE_EXPAND_FILL

	type[attribute_name] = [amount, newBar]

# 속성 중 가장 작은 속성 추출 (0이거나 인자로 주어진 속성 제외) 
func find_min(skip: String) -> String:
	if (type.size() == 1):
		return type.keys()[0]
	
	# 주어진 속성을 제외한 최소값 구하기.
	var n = AttributeInformation.NONE_ATTRIBUTE
	var min_value = max_value + 10
	for i in type:
		if i == skip or type[i][0] == 0: continue
		if type[i][0] < min_value:
			min_value = type[i][0]
			n = i
	return n

func _on_threshold_exceeded(attribute_name: String, active_type: ThresholdActiveType):
	match active_type:
		ThresholdActiveType.EXPLODE:
			# 임계점 넘긴 속성은 0으로 초기화
			reset_value(attribute_name)

		# 임계점 넘긴 속성 강조 표시
		ThresholdActiveType.KEEP:
			threshold_exceeded = attribute_name
			var co = AttributeInformation.get_attribute_color(attribute_name)
			co = co.darkened(0.5)
			co.a = 0.3
			background_color.color = co

func _on_threshold_recovered(attribute_name: String):
	if threshold_exceeded == attribute_name:
		threshold_exceeded = ""
		background_color.color = Color(0, 0, 0, 0)
