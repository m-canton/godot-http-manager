extends PanelContainer

signal pressed

@onready var name_label: Label = $VBoxContainer/HBoxContainer/NameLabel
@onready var id_label: Label = $VBoxContainer/HBoxContainer/IdLabel
@onready var data_label: Label = $VBoxContainer/DataLabel


var _is_pressed := false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
			elif _is_pressed:
				pressed.emit()
	elif event is InputEventMouseMotion and _is_pressed:
		_is_pressed = false

func fill_with_object(object_data: Dictionary) -> void:
	if not is_node_ready():
		push_warning("Node is not ready.")
		return
	
	id_label.text = "#" + object_data.get("id", "")
	name_label.text = object_data.get("name", "")
	
	data_label.text = ""
	var data = object_data.get("data")
	if data is Dictionary:
		data_label.show()
		for key in data:
			data_label.text += "* " + key + ": " + str(data[key]) + "\n"
	else:
		data_label.hide()
