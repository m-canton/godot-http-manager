class_name HTTPManagerRequest extends RefCounted

signal completed(response: HTTPManagerResponse)

## HTTPManager Request class.
## 
## This class requests from a [HTTPManagerRoute] according to client
## restrictions. Use [method create_from_route] to create a instance because
## it adds the client and route headers to this and sets the route for you.

## Route resource.
var route: HTTPManagerRoute
## Overrides route priority. See [HTTPManagerRoute.priority].
var priority := -1
## Headers.
var headers := PackedStringArray()
## Authentication.
var use_auth := false
## Body.
var body := ""
## Url params.
var url_params := ""

## TLS Options.
var tls_options: TLSOptions

## Emits [signal completed] signal with the response. Used by HTTPManager when
## response is completed or gets a error.
func complete(response: HTTPManagerResponse) -> void:
	completed.emit(response)


func get_uri() -> String:
	if route:
		return route.endpoint + ("" if url_params.is_empty() else ("?" + url_params))
	return ""


func _parse_query_dict(dict: Dictionary) -> PackedStringArray:
	var array := PackedStringArray()
	var _first := true
	for key in dict:
		var value = dict[key]
		if value is Dictionary:
			for value_key in value:
				_parse_query_dict(value)
		elif value is Array:
			_parse_query_array(value)
		else:
			array.append(str("[", key, "]=", str(value).uri_encode()))
	return array


func _parse_query_array(array: Array) -> PackedStringArray:
	var r := PackedStringArray()
	for i in range(array.size()):
		var value = array[i]
		if value is Dictionary:
			for value_key in value:
				_parse_query_dict(value)
		elif value is Array:
			_parse_query_array(value)
		else:
			array.append(str("[", i, "]=", str(value).uri_encode()))
	return r

#region Authentication
## Adds Basic Authentication header.
func with_basic_auth(username: String, password: String) -> HTTPManagerRequest:
	_with_auth("Basic " + Marshalls.utf8_to_base64(username + ":" + password))
	return self

## Adds Basic Authentication header. Not implementet yet.
func with_diggest_auth(_username: String, _password: String) -> HTTPManagerRequest:
	push_error("Not implemented yet.")
	return self


func _with_auth(type_credentials_string: String) -> void:
	headers.append("Authorization: " + type_credentials_string)
	use_auth = true
#endregion

## Adds this request to client queue.
func start(query := {}) -> HTTPManagerRequest:
	var query_array := PackedStringArray()
	for key in query:
		var value = query[key]
		if value is Dictionary:
			var arr := _parse_query_dict(value)
			for a in arr:
				query_array.append(str(key, a))
		elif value is Array:
			var parsed_array := _parse_query_array(value)
		elif value is bool:
			query_array.append(str(key, "=", "1" if value else "0"))
		else:
			query_array.append(str(key, "=", str(value).uri_encode()))
	url_params = "&".join(query_array)
	HTTPManager.request(self)
	return self

func with_body(b) -> HTTPManagerRequest:
	if b is Array or b is Dictionary:
		body = JSON.stringify(b)
	elif b is String:
		body = b
	else:
		push_warning("Not valid body")
	return self

## Creates a request instance from a route.
static func create_from_route(r: HTTPManagerRoute) -> HTTPManagerRequest:
	var re := HTTPManagerRequest.new()
	if not r:
		push_error("Creating a request with null route.")
		return null
	
	re.route = r
	re.headers.append_array(r.headers)
	re.headers.append_array(r.client.headers)
	return re
