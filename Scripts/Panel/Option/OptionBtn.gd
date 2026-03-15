extends Node


func _ready():
	#var bar = $"ColorRect/HScrollBar" as HScrollBar
	#bar.value = ViewManager.panel_ratio
	pass
# UI 표시
func toggle_UI(open: bool) -> void:
	if open:
		get_child(0).show()
	else:
		get_child(0).hide()

func change_panel_ratio(value: float):
	# TODO : 상단과 하단 패널의 비율을 조정하는 기능 수정 필요
	ViewManager.panel_ratio = value

# 게임 종료 함수
func quit():
	get_tree().quit()
