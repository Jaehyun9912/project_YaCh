extends Control



# 정보 종류 텍스트
var type:
	get:
		return $"ColorRect/TextType"

# 정보 값 텍스트
var text:
	get:
		return $"ColorRect/Detail"





func _ready():
	get_window().size_changed.connect(_on_size_changed)
	_on_size_changed()
	

func _on_size_changed():
	var current_orientation = ViewManager.screen_mode
	if current_orientation == 0:
		self.anchor_right = 0.5
		self.anchor_bottom = 1
	elif current_orientation == 1:
		self.anchor_right = 1
		self.anchor_bottom = 0.5



var panel:
	get:
		return $"ColorRect" as Control

# 체력 값 업데이트
func set_hp_panel():
	panel.anchor_right = 0.4
	set_text("현재 체력",str(PlayerData.hp) + " / " + str(PlayerData.max_hp))

# 보유 골드 현황 업데이트
func set_budget_panel():
	panel.anchor_right = 0.4
	set_text("보유 골드","10000" + " 골드")

# 디버그용 빌드 로그 띄우기
func set_debug_panel():
	panel.anchor_right = 0.4
	set_text("현재 모드", str(DisplayServer.screen_get_orientation()))

func set_text_panel():
	panel.anchor_right = 1
	set_text()

func set_text(title = "", discription = ""):
	type.text = title
	text.text = discription
	
	
