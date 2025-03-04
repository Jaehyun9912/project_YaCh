extends Control


# 패널 정보 모드
enum Mode{
	HP,
	BUDGET,
	DEBUG,
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
	get_window().size_changed.connect(_on_size_changed)
	_on_size_changed()

func _on_size_changed():
	var current_orientation = DisplayServer.screen_get_orientation()
	if current_orientation == DisplayServer.SCREEN_LANDSCAPE:
		self.anchor_right = 0.5
		self.anchor_bottom = 1
	elif current_orientation == DisplayServer.SCREEN_PORTRAIT:
		self.anchor_right = 1
		self.anchor_bottom = 0.5
	mode = 2

func _process(delta):
	if is_visible:
		set_panel()


# 모드에 맞는 값 업데이트
func set_panel():
	if mode == Mode.HP:
		set_hp_panel()
	elif mode == Mode.BUDGET:
		set_budget_panel()
	elif mode == Mode.DEBUG:
		set_debug_panel()


# 체력 값 업데이트
func set_hp_panel():
	type.text = "현재 체력"
	text.text = str(PlayerData.hp) + " / " + str(PlayerData.max_hp)

# 보유 골드 현황 업데이트
func set_budget_panel():
	type.text = "보유 골드"
	text.text = "10000" + " 골드"

# 디버그용 빌드 로그 띄우기
func set_debug_panel():
	type.text = "현재 모드"
	text.text = str(DisplayServer.screen_get_orientation())
