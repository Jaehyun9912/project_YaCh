extends Node

@export var panel_name: String
@export var screen_location: ViewManager.SCREEN

signal on_location_interacted()

func _on_input_event(_camera:Node, _event:InputEvent, _position:Vector3, _normal:Vector3, _shape_idx:int):
    if _event is InputEventMouseButton and _event.pressed:
        on_location_interacted.emit()
        var meta_data = Dictionary()
        for i in get_meta_list():
            meta_data[i] = get_meta(i)

        ViewManager.push_panel(panel_name, screen_location, meta_data)



