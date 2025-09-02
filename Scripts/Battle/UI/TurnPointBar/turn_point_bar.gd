class_name TurnPointBar extends Control

@onready var turn_point_obj = preload("res://Objects/UI/Battle/TurnPointBar/TurnPoint.tscn")

var turn_bar_dict := {}

var color_list = [Color.RED, Color.BLUE, Color.GREEN]
var idx = 0

signal end_set_point

# 캐릭터 리스트를 받아서 행동력 바를 추가함 
func set_information(chars: Array):
	var hContainer = $HBoxContainer
	for i in chars:
		var new_bar = turn_point_obj.instantiate()
		hContainer.add_child(new_bar)
		
		# 색은 일단 정해진 순서를 돌아가며 설정함
		# 이것은 나중에 바꿔야함 
		new_bar.init(i.point, i.name, color_list[idx])
		idx += 1
		
		turn_bar_dict[i.name] = new_bar	
		
		# 죽을 경우 제거 함수가 자동으로 발동 
		i.character_died.connect(remove_bar)
		
# 각 캐릭터의 행동력 최대치를 재설정함 
func set_point(chars: Array, total_value):
	$Label.text = "Total Point : " + str(total_value)
	for i in chars:
		var ch = turn_bar_dict.get(i.name, null)
		if ch != null:
			ch.size_flags_stretch_ratio = float(i.point) / total_value
			ch.set_max_point(i.point)
	
	await turn_bar_dict[chars[0].name].end_anim
	end_set_point.emit()
		
# 바뀐 행동력을 반영함 
func update_point(character: BattleCharacter):
	turn_bar_dict[character.name].set_point(character.current_point)

func set_outline(character: BattleCharacter, is_counter: bool):
	for i in turn_bar_dict.keys():
		turn_bar_dict[i].set_outline(i == character.name, is_counter)

# 캐릭터가 죽었을 때 행동력 바를 정리함 
func remove_bar(character: BattleCharacter):
	var char_name = character.name
	var removed_bar = turn_bar_dict[char_name]
	
	removed_bar.set_point(0)
	turn_bar_dict.erase(char_name)
	
	# 한 바퀴가 돌면 그 뒤에 제거하기 (빈칸으로 냅두기 위함)
	await end_set_point
	
	removed_bar.queue_free()
	
# 최초 등장 애니메이션
func first_appear_anim():
	var tween = create_tween()
	var bar = $ProgressBar
	
	tween.tween_property(bar, "value", bar.max_value, 1)
	await tween.finished
	
	var timer = Timer.new()
	add_child(timer)
	timer.start(0.3)
	await timer.timeout
	
	$HBoxContainer.visible = true
	for i in turn_bar_dict.values():
		var bar_tween = i.create_tween() as Tween
		bar_tween.tween_property(i.fill, "bg_color:a", 1, 0.5)
	timer.start(0.5)
	await timer.timeout
	timer.queue_free()
	$ProgressBar.queue_free()
		
	
	end_set_point.emit()
