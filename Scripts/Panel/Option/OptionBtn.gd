extends Node



func _ready():
	var bar = $"ColorRect/HScrollBar" as HScrollBar
	bar.value = ViewManager.panel_ratio
# UI 표시
func toggle_UI(open : bool) -> void:
	if open:
		get_child(0).show()
	else:
		get_child(0).hide()

func change_panel_ratio(value : float):
	ViewManager.panel_ratio = value

# 게임 종료 함수
func quit():
	get_tree().quit()


