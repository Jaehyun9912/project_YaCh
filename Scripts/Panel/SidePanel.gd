extends Control



# 패널 정보 모드
enum Mode{
	HP,
	BUDGET,
	INFO
}


var panel:
	get:
		return $"ColorRect" as Control
# 정보 종류 텍스트
var type:
	get:
		return $"ColorRect/TextType"

# 정보 값 텍스트
var text:
	get:
		return $"ColorRect/Detail"


var _x_length : float

func _ready():
	get_window().size_changed.connect(_on_size_changed)
	_on_size_changed()
	#print("Pos : ",panel.position,"/Size : ",panel.size)
	

func _on_size_changed():
	var current_orientation = ViewManager.screen_mode
	if current_orientation == 0:
		self.anchor_right = 0.5
		self.anchor_bottom = 1
	elif current_orientation == 1:
		self.anchor_right = 1
		self.anchor_bottom = 0.5
	panel.size.x = size.x*_x_length


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
	_set_length(0.4)
	set_text("현재 체력",str(PlayerData.hp) + " / " + str(PlayerData.max_hp))

# 보유 골드 현황 업데이트
func set_budget_panel():

	type.text = "보유 골드"
	text.text = "10000" + " 골드"
  _set_length(0.4)
	set_text("보유 골드","10000" + " 골드")
	
# 정보 설정하기 
func set_info_panel(type_str: String, text_str: String):
	mode = Mode.INFO
	type.text = type_str
	text.text = text_str

# 일정 시간동안만 표시
func set_info_panel_with_time(Title: String, Info: String, wait: float, end_mode := Mode.HP):
	visible = true
	set_info_panel(Title, Info)
	
	var timer = $Timer as Timer
	timer.start(wait)
	await timer.timeout
	
	match end_mode:
		Mode.HP: set_hp_panel()
		Mode.BUDGET: set_budget_panel()

# 디버그용 빌드 로그 띄우기
func set_debug_panel():
	_set_length(0.4)
	set_text("현재 모드", str(DisplayServer.screen_get_orientation()))

# 대화용 패널 크기 확장
func set_text_panel():
	_set_length(1)
	set_text()

# 패널 텍스트 설정
func set_text(title = "", discription = ""):
	type.text = title
	text.text = discription
	
func _set_length(value : float) -> void:
	_x_length = value
	panel.size.x = size.x*value;
	
	
