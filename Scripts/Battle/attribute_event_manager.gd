class_name AttributeEventManager extends Node

var _attribute_bar : AttributeBar
var _battle_manager : BattleManager

func init(attribute: AttributeBar, battle_manager: BattleManager):
	_attribute_bar = attribute
	_attribute_bar.attribute_threshold_exceeded.connect(_on_threshold_exceeded)
	_attribute_bar.attribute_threshold_recovered.connect(_on_threshold_recovered)
	_battle_manager = battle_manager

func _on_threshold_exceeded(attribute_name: String, active_type: AttributeBar.ThresholdActiveType):
	print("Threshold Exceeded for attribute: %s, Type: %s" % [attribute_name, str(active_type)])
	var attribute = AttributeInformation.get_attribute(attribute_name)
	if attribute == null:
		printerr("Invalid attribute name: " + attribute_name)
		return
	var effects = attribute["overdrive"].get("effects", null)
	if effects != null:
		_battle_manager.effect_manager.add_effects(effects, "all", attribute_name)


func _on_threshold_recovered(attribute_name: String):
	print("Threshold Recovered for attribute: %s" % attribute_name)
	_battle_manager.effect_manager.remove_effects(attribute_name)
