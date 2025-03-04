extends Control


# 패널 정보 모드
enum Mode{
	HP,
	BUDGET,
	INFO
}

# 정보 종류 텍스트
var type:
	get:
		return $"ColorRect/VBoxContainer/TextType"

# 정보 값 텍스트
var text:
	get:
		return $"ColorRect/VBoxContainer/Detail"

var mode : 
	get:
		return mode
	set(value):
		mode = value
		set_panel()




func _ready():
	mode = Mode.HP
	pass


func _process(delta):
	if is_visible:
		set_panel()


# 모드에 맞는 값 업데이트
func set_panel():
	if mode == Mode.HP:
		set_hp_panel()
	elif mode == Mode.BUDGET:
		set_budget_panel()
	# 모드 바꾸는 걸로 원하는 내용 넣기가 힘들어서 얘만 함수로 빼냈습니다.
	elif mode == Mode.INFO:
		return

# 체력 값 업데이트
func set_hp_panel():
	type.text = "현재 체력"
	text.text = str(PlayerData.hp) + " / " + str(PlayerData.max_hp)

# 보유 골드 현황 업데이트
func set_budget_panel():
	type.text = "보유 골드"
	text.text = "10000" + " 골드"
	
# 정보 설정하기 
func set_info_panel(type_str: String, text_str: String):
	mode = Mode.INFO
	type.text = type_str
	text.text = text_str
