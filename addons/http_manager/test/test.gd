extends Node

const RESTFUL_API_OBJECTS = preload("res://addons/http_manager/test/restful_api/routes/objects.tres")

@onready var objects_button: Button = $HBoxContainer/ObjectsButton
@onready var line_edit: LineEdit = $HBoxContainer/LineEdit

func _ready():
	objects_button.pressed.connect(_on_objects_requested)
	line_edit.text_submitted.connect(_on_object_id_submitted)


func _on_objects_requested() -> void:
	objects_button.disabled = true
	HTTPManagerRequest.create_from_route(RESTFUL_API_OBJECTS).start({
		id = [1, 2, 3, 4]
	}).completed.connect(_on_objects_received)


func _on_objects_received(response: HTTPManagerResponse) -> void:
	objects_button.disabled = false
	if response.successful:
		print("Objects: ", response.parse().size())
	else:
		push_error("Response error.")


func _on_object_id_submitted(text: String) -> void:
	if text.is_empty():
		push_warning("'text' must not be empty.")
		return
	
	HTTPManagerRequest.create_from_route(preload("res://addons/http_manager/test/restful_api/routes/objects_show.tres")).start({
		id = text,
	}).completed.connect(_on_object_received)


func _on_object_received(response: HTTPManagerResponse) -> void:
	if response.successful:
		var data = response.parse()
		print("Object %s\n- name: %s\n- data: %s\n" % [data.id, data.name, str(data.data)])
	else:
		push_error("Response error.")
