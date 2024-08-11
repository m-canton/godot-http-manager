extends Node

const RESTFUL_API_OBJECTS = preload("res://addons/http_manager/test/restful_api/routes/objects.tres")


func _ready():
	_init_search_many()
	_init_search_one()
	_init_edit_container()


#region Search Many
const OBJECT_CARD = preload("res://addons/http_manager/test/object_card.tscn")

@onready var objects_button: Button = $MarginContainer/HBoxContainer/Objects/SearchButton
@onready var object_list: VBoxContainer = $MarginContainer/HBoxContainer/Objects/ScrollContainer/VBoxContainer

func _init_search_many() -> void:
	objects_button.pressed.connect(_on_objects_requested)

func _on_objects_requested() -> void:
	#objects_button.disabled = true
	var r := RESTFUL_API_OBJECTS.create_request()
	if HTTPManager.request(r) == OK:
		r.completed.connect(_on_objects_received)

func _on_objects_received(response: HTTPManagerResponse) -> void:
	#objects_button.disabled = false
	if response.successful:
		var objects = response.parse()
		if objects is Array:
			for c in object_list.get_children():
				c.queue_free()
			
			for object in objects:
				var card := OBJECT_CARD.instantiate()
				object_list.add_child(card)
				card.fill_with_object(object)
				card.pressed.connect(_select_object.bind(object))
	else:
		push_error("Response error.")
#endregion


#region Search One
@onready var line_edit: LineEdit = $MarginContainer/HBoxContainer/ObjectsShow/LineEdit
@onready var searched_object_card: PanelContainer = $MarginContainer/HBoxContainer/ObjectsShow/ObjectCard

func _init_search_one() -> void:
	line_edit.text_submitted.connect(_on_object_id_submitted)

func _on_object_id_submitted(text: String) -> void:
	if not line_edit.editable:
		return
	
	if text.is_empty():
		push_warning("'text' must not be empty.")
		return
	
	var request: HTTPManagerRequest = get_node("/root/HTTPManager").create_request_from_route(preload("res://addons/http_manager/test/restful_api/routes/objects_show.tres"), {
		id = text,
	})
	if request.start() == OK:
		line_edit.editable = false
		request.completed.connect(_on_object_received)

func _on_object_received(response: HTTPManagerResponse) -> void:
	line_edit.editable = true
	if response.successful:
		var data = response.parse()
		if data is Dictionary:
			if data.has("error"):
				push_error(data["error"])
				searched_object_card.hide()
			else:
				searched_object_card.show()
				searched_object_card.fill_with_object(data)
	else:
		push_error("Response error.")
#endregion


#region Edit
const OBJECT_DATA_FIELD = preload("res://addons/http_manager/test/object_data_field.tscn")

var _editing_object := "":
	set(value):
		if _editing_object != value:
			_editing_object = value
			_update_edit_title()
			_update_edit_button()
var _requesting_edit := false:
	set(value):
		if _requesting_edit != value:
			_requesting_edit = value
			_update_edit_button()

@onready var edit_title_label: Label = $MarginContainer/HBoxContainer/ObjectsEdit/HBoxContainer/Label
@onready var edit_reset_button: Button = $MarginContainer/HBoxContainer/ObjectsEdit/HBoxContainer/Button

@onready var name_line_edit: LineEdit = $MarginContainer/HBoxContainer/ObjectsEdit/NameControl/LineEdit
@onready var data_fields: VBoxContainer = $MarginContainer/HBoxContainer/ObjectsEdit/DataControl/VBoxContainer/Fields
@onready var data_add_button: Button = $MarginContainer/HBoxContainer/ObjectsEdit/DataControl/VBoxContainer/AddButton

@onready var edit_button: Button = $MarginContainer/HBoxContainer/ObjectsEdit/Button

@onready var edit_message_label: Label = $MarginContainer/HBoxContainer/ObjectsEdit/MessageLabel

func _init_edit_container() -> void:
	edit_reset_button.pressed.connect(_select_object.bind({}))
	data_add_button.pressed.connect(_add_data_field)
	edit_button.pressed.connect(_on_create_or_update_object)
	_update_edit_title()
	_update_edit_button()

func _update_edit_title() -> void:
	if _editing_object.is_empty():
		edit_title_label.text = "Create Object"
	else:
		edit_title_label.text = "Edit Object #" + _editing_object

func _update_edit_button() -> void:
	if _editing_object.is_empty():
		if _requesting_edit:
			edit_button.text = "Creating..."
		else:
			edit_button.text = "Create"
	else:
		if _requesting_edit:
			edit_button.text = "Updating..."
		else:
			edit_button.text = "Update"

func _select_object(dict: Dictionary) -> void:
	_editing_object = dict.get("id", "")
	name_line_edit.text = dict.get("name", "")
	
	for c in data_fields.get_children():
		c.queue_free()
	
	var data = dict.get("data")
	if data is Dictionary:
		for key in data:
			var n := OBJECT_DATA_FIELD.instantiate()
			data_fields.add_child(n)
			n.get_child(0).text = key
			n.get_child(1).text = str(data[key])

func _add_data_field() -> void:
	data_fields.add_child(OBJECT_DATA_FIELD.instantiate())

func _on_create_or_update_object() -> void:
	var validated_data = {}
	if _validate(validated_data) != OK:
		return
	
	if _editing_object.is_empty():
		var request: HTTPManagerRequest = get_node("/root/HTTPManager").create_request_from_route(preload("res://addons/http_manager/test/restful_api/routes/objects_store.tres")) \
				.with_body(validated_data, HTTPManagerRequest.MIME.JSON)
		
		if request.start() == OK:
			edit_button.disabled = true
			edit_reset_button.disabled = true
			request.completed.connect(_on_object_updated)
	else:
		var request: HTTPManagerRequest = get_node("/root/HTTPManager").create_request_from_route(preload("res://addons/http_manager/test/restful_api/routes/objects_update.tres"), {
			id = _editing_object,
		}).with_body(validated_data, HTTPManagerRequest.MIME.JSON)
		
		if request.start() == OK:
			edit_button.disabled = true
			edit_reset_button.disabled = true
			request.completed.connect(_on_object_updated)

func _validate(validated_data: Dictionary) -> Error:
	validated_data["name"] = name_line_edit.text
	validated_data["data"] = {}
	
	for c in data_fields.get_children():
		var ckey = c.get_child(0).text
		if ckey.is_empty():
			push_error("Data field key cannot be empty.")
			return FAILED
		
		var cvalue = c.get_child(1).text
		validated_data["data"][ckey] = cvalue
	return OK

func _on_object_updated(response: HTTPManagerResponse) -> void:
	edit_reset_button.disabled = false
	edit_button.disabled = false
	if response.successful:
		var dict: Dictionary = response.parse()
		if dict.has("error"):
			edit_message_label.text = dict["error"]
			var red_color := Color.RED
			red_color.a = 0.9
			edit_message_label.add_theme_color_override("font_color", red_color)
		else:
			if _editing_object.is_empty():
				print("Object created: ", dict)
			else:
				print("Object updated: ", dict)
			
			_select_object(dict)
	else:
		push_error("Error updating object.")
#endregion
