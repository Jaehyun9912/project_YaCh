class_name AttributeEventManager extends Node

var attribute_bar : AttributeBar

func init(attribute: AttributeBar):
	attribute_bar = attribute
	attribute_bar.attribute_threshold_exceeded.connect(_on_threshold_exceeded)
	attribute_bar.attribute_threshold_recovered.connect(_on_threshold_recovered)

func _on_threshold_exceeded(attribute_name: String, active_type: AttributeBar.ThresholdActiveType):
	print("Threshold Exceeded for attribute: %s, Type: %s" % [attribute_name, str(active_type)])

func _on_threshold_recovered(attribute_name: String):
	print("Threshold Recovered for attribute: %s" % attribute_name)
