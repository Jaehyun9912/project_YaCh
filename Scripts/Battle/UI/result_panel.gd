class_name ResultPanel extends Control

signal check_button_pressed

func _ready():
	visible = false

# 승리 처리 (보상 계산 포함)
func process_win(rewards: BattleData.Rewards):
	var reward_text = _calculate_and_give_rewards(rewards)
	set_panel("전투에서 승리했다!", "보상", reward_text)

# 패배 처리
func process_lose():
	set_panel("전투에서 패배했다...")

# 도주 처리
func process_run():
	set_panel("전투에서 도망쳤다!")

# 보상 계산 및 지급
func _calculate_and_give_rewards(rewards: BattleData.Rewards) -> String:
	var reward_str = ""
	
	# var gold_reward = rewards.gold
	var items_to_reward = rewards.items

	for i in items_to_reward:
		var item_id = i.id
		if item_id == null:
			printerr("No Item ID in rewards!")
			continue

		var item = DataManager.get_item_artifact_data(item_id)
		var count = i.count

		# 텍스트 추가
		reward_str += item.get("display", {}).get("name", "알 수 없는 아이템")
		if count > 1:
			reward_str += " " + str(count) + "개"
		reward_str += "\n"
		
		# 실제 아이템 지급
		PlayerData.add_new_item(item_id, count)
			
	return reward_str

# 패널 텍스트 설정 함수
func set_panel(title_text, subtitle_text = "", info_text = ""):
	visible = true
	
	if subtitle_text == "" and info_text == "":
		set_text($ColorRect/SingleTitle, title_text)
	else:
		set_text($ColorRect/Title, title_text)
		set_text($ColorRect/SubTitle, subtitle_text)
		set_text($ColorRect/Info, info_text)
	$ColorRect/Button.visible = true
		
func close_panel():
	visible = false
	for i in $ColorRect.get_children():
		i.visible = false

func set_text(panel, txt):
	panel.text = txt
	panel.visible = true

func _on_button_pressed():
	check_button_pressed.emit()
