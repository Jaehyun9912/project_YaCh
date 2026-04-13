extends Node
class_name EnemyManager

# TODO: BattleManager에서 적 정보 가져오는 로직 수정 필요 
@onready var battle = $".." as BattleManager
@onready var character_manager = $"../CharacterManager" as CharacterManager

var current_character: BattleCharacter:
	get: return battle.now_character
var current_skill: SkillData
var player: BattleCharacter:
	get: return battle.player_character

var damage: float
var effect_id: String

var timer: Timer

func _ready():
	timer = Timer.new() as Timer
	add_child(timer)

func init(_battle_manager: BattleManager):
	battle = _battle_manager
	battle.turn_character_changed.connect(_on_turn_character_changed)

func _on_turn_character_changed(new_character: BattleCharacter):
	if new_character == null or new_character.is_player:
		return
	
	# 적 턴이면 행동 개시
	_enemy_turn()

func _enemy_turn():
	# 0.5초 대기 후 행동
	timer.start(0.5)
	await timer.timeout

	# 1. 스킬 선택 (현재는 첫 번째 스킬 고정)
	var skills = current_character.skills
	if skills.size() == 0:
		battle.turn_end.emit()
		return
		
	var skill_id = skills[0]
	current_skill = SkillManager.get_skill(skill_id) # Enemy skill도 SkillManager에서 관리한다고 가정
	
	if current_skill == null:
		battle.turn_end.emit()
		return
		
	# 2. 데미지 계산 및 로그
	# 첫 번째 액션의 데미지 공식을 기준으로 함
	damage = 0
	if current_skill.execution.actions.size() > 0:
		var action = current_skill.execution.actions[0]
		if action.type == "damage":
			damage = calculate_formula(action.formula, current_character)
			damage *= battle.field_stat.get(action.element, 1.0)
	
	ViewManager.side_panel.set_info_panel_with_time(current_skill.display.name, current_skill.display.description % damage, 2)
	
	# 3. 비용 제거 및 캐스팅 시작
	battle.remove_cost(current_skill)
	battle.set_casting_panel("마법 구축 중", SkillManager.get_casting_time(current_skill, battle.attribute_bar), CastingPanel.CastingButtonType.Counter, _on_end_casting)

func calculate_formula(formula: SkillData.Execution.Action.Formula, caster: BattleCharacter) -> float:
	var stat_val = caster.stat_manager.get_stat(formula.scaling_stat, 0.0)
	return formula.base + (stat_val * formula.multiplier)

func _on_end_casting(is_success):
	if is_success:
		timer.start(0.1)
		await timer.timeout
		battle.set_casting_panel("마법 시전 중", SkillManager.SKILL_ACTIVE_TIME, CastingPanel.CastingButtonType.Parrying, _on_end_spell)
	else:
		battle.turn_end.emit()

func _on_end_spell(is_success):
	if is_success:
		# 스킬 효과 적용
		apply_skill_effects()
	
	battle.turn_end.emit()

func apply_skill_effects():
	# AttackManager의 로직과 유사하게 처리 (중복 제거를 위해 AttackManager 기능을 활용할 수도 있음)
	var execution = current_skill.execution
	
	for action in execution.actions:
		if randf() > action.chance: continue
		
		match action.type:
			"damage":
				var val = calculate_formula(action.formula, current_character)
				val *= battle.field_stat.get(action.element, 1.0)
				var actual_dmg = player.apply_damage(val)
				battle.add_attack_log(current_character.name, player.name, actual_dmg, player.hp)
			"buff", "debuff":
				if action.effect_id != "":
					player.add_buff(action.effect_id, 1) # 적이 거는 버프/디버프
			
	# 원소 변화 적용
	if execution.element.size() > 0:
		battle.set_attribute_change(execution.element)
	
	ViewManager.side_panel.set_hp_panel()
