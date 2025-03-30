extends Control
class_name ChoiceButtonManager

@onready var button_texture = load("res://Objects/UI/Battle/RoundButton/round_button.png")
@export var button_color = Color.DIM_GRAY
@export var button_size := Vector2(80, 80)
@export var radius = 3

var button_list := []

# 버튼 생성하기 
func _generate_button(pos, btn_size):
	var btn := TextureRect.new()
	add_child(btn)
	btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btn.texture = button_texture
	btn.scale = Vector2(1, 1)
	btn.size = btn_size
	btn.global_position = pos
	btn.modulate = button_color
	
	return btn
	
# 버튼 생성하고 정보 입력 및 애니메이션 설정 
func generate_button_with_anim(start_pos, target_pos):
	var btn = _generate_button(start_pos, button_size)
	var tween = create_tween() as Tween
	tween.tween_property(btn, "global_position", target_pos, 0.2)
	
	button_list.append(btn)
	
# 버튼을 정해진 개수만큼 돌려가면서 배치
func set_choice_button(count, start_pos, start_angle, angle_max):
	var angle = start_angle
	for i in range(count):
		var target_pos = start_pos + polar_to_cartesian(radius, angle)
		generate_button_with_anim(start_pos, target_pos)
		angle += angle_max / count
		
# 주어진 반지름 r, 각도 angle 기준으로 위치 계산
func polar_to_cartesian(r: float, angle: float) -> Vector2:
	angle = deg_to_rad(angle)
	return Vector2(r * cos(angle), r * sin(angle))
	
# 주어진 좌표와 global_pos가 가장 가까운 버튼의 인덱스 반환 
func get_nearest_button(pos: Vector2):
	if len(button_list) == 0: return null
	
	var max_button = 0
	var max_dist = 100000000
	
	for i in range(len(button_list)):
		var dist = pos.distance_to(get_button_center(i))
		if dist < max_dist:
			max_button = i
			max_dist = dist
	return max_button
	
func remove_all_button():
	for i in button_list:
		i.queue_free()
	button_list.clear()

func get_button_center(index):
	return button_list[index].position + button_size / 2
	
func make_button_special(index, color = Color.RED):
	for i in range(len(button_list)):
		if i == index:
			button_list[i].modulate = color
		else:
			button_list[i].modulate = button_color
