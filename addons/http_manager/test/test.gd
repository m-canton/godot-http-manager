extends Node

const RESTFUL_API_OBJECTS = preload("res://addons/http_manager/test/restful_api/routes/objects.tres")

@onready var objects_button: Button = $HBoxContainer/ObjectsButton

func _ready():
	objects_button.pressed.connect(_on_objects_requested)


func _on_objects_requested() -> void:
	objects_button.disabled = true
	HTTPManagerRequest.create_from_route(RESTFUL_API_OBJECTS).start({
		
	}).completed.connect(_on_objects_received)


func _on_objects_received(response: HTTPManagerResponse) -> void:
	objects_button.disabled = false
	print("Objects: ", response.parse().size())
