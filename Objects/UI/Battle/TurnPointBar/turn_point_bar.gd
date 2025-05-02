class_name TurnPointBar extends Control

@onready var turn_point_obj = preload("res://Objects/UI/Battle/TurnPointBar/TurnPoint.tscn")

var turn_bar_dict = {}

var color_list = [Color.RED, Color.BLUE, Color.GREEN]
var idx = 0

signal end_set_point

# 캐릭터 리스트를 받아서 행동력 바를 추가함 
func set_information(chars: Array):
	for i in chars:
		var new_bar = turn_point_obj.instantiate()
		
		# 색은 일단 정해진 순서를 돌아가며 설정함
		# 이것은 나중에 바꿔야함 
		new_bar.init(i.point, i.name, color_list[idx])
		idx += 1
		
		$HBoxContainer.add_child(new_bar)
		
		turn_bar_dict[i.name] = new_bar	
		
		# 죽을 경우 제거 함수가 자동으로 발동 
		i.character_died.connect(remove_bar)
		
# 각 캐릭터의 행동력 최대치를 재설정함 
func set_point(chars: Array, total_value):
	$Label.text = "Total Point : " + str(total_value)
	for i in chars:
		turn_bar_dict[i.name].size_flags_stretch_ratio = float(i.point) / total_value
		turn_bar_dict[i.name].set_point(i.point)
	end_set_point.emit()
		
# 바뀐 행동력을 반영함 
func update_point(char: BattleCharacter):
	turn_bar_dict[char.name].set_ratio(char.current_point)

# 캐릭터가 죽었을 때 행동력 바를 정리함 
func remove_bar(char):
	var char_name = char.name
	var removed_bar = turn_bar_dict[char_name]
	removed_bar.set_ratio(0)
	turn_bar_dict.erase(char_name)
	
	# 한 바퀴가 돌면 그 뒤에 제거하기 (빈칸으로 냅두기 위함)
	await end_set_point
	
	removed_bar.queue_free()
	
