class_name HTTPManagerRequest extends RefCounted

signal completed(response: HTTPManagerResponse)

## Route resource.
var route: HTTPManagerRoute
## Request query.
var query := {}
## Overrides route priority. See [HTTPManagerRoute.priority].
var priority := -1
## Headers.
var headers := PackedStringArray()
## Authentication.
var use_auth := false
## Body.
var body := ""


func _init(r: HTTPManagerRoute) -> void:
	if not r:
		push_error("Creating a request with null route.")
		return
	
	route = r
	headers.append_array(r.headers)
	headers.append_array(r.client.headers)



func complete(response: HTTPManagerResponse) -> void:
	completed.emit(response)


func _query_dict_to_string(dict: Dictionary, prefix := "") -> String:
	var s := ""
	var _first := true
	for key in dict:
		var value = dict[key]
		if value is Dictionary:
			_query_dict_to_string(value, )
		elif value is Array:
			if prefix.is_empty():
				_query_dict_to_string(value, key)
			else:
				_query_dict_to_string(value, prefix + "[" + key + "]")
		else:
			s += str(prefix, key, "=", str(value).uri_encode())
	return s


func _query_array_to_string(_array: Array) -> String:
	var s := ""
	return s

#region Authentication
## Adds Basic Authentication header.
func with_basic_auth(username: String, password: String) -> void:
	_with_auth("Basic " + Marshalls.utf8_to_base64(username + ":" + password))

## Adds Basic Authentication header. Not implementet yet.
func with_diggest_auth(_username: String, _password: String) -> void:
	push_error("Not implemented yet.")


func _with_auth(type_credentials_string: String) -> void:
	headers.append("Authorization: " + type_credentials_string)
	use_auth = true
#endregion


func start() -> void:
	HTTPManager.request(self)
