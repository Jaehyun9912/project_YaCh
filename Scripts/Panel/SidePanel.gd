extends Control

var type:
	get:
		return $"ColorRect/VBoxContainer/TextType"
var text:
	get:
		return $"ColorRect/VBoxContainer/Detail"

enum Mode{
	Hp,
	Budget
}
var mode :
	get:
		return mode
	set(value):
		mode = value
		set_panel()

func _ready():
	pass

func set_panel():
	if mode == Mode.Hp:
		set_hp_panel()
	elif mode == Mode.Budget:
		set_budget_panel()
func set_hp_panel():
	type.text = "현재 체력"
	text.text = str(PlayerData.hp) + " / " + str(PlayerData.max_hp)

func set_budget_panel():
	type.text = "보유 골드"
	text.text = "10000" + " 골드"
