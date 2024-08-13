class_name HTTPManagerRequest extends RefCounted

signal completed(response: HTTPManagerResponse)

static var http_manager: Node

## HTTPManager Request class.
## 
## This class requests from a [HTTPManagerRoute] according to client
## restrictions. Use [method create_from_route] to create a instance because
## it adds the client and route headers to this and sets the route for you.

enum Mode {
	DEFAULT,
	FETCH,
}

enum Listener {
	COMPLETE,
	SUCCESS,
	FAILURE,
}

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
## Mode.
var mode := Mode.DEFAULT
## Parsed URI.
var _parsed_uri := ""

## TLS Options.
var tls_options: TLSOptions

## Emits [signal completed] signal with the response. Used by HTTPManager when
## response is completed or gets a error.
func complete(response: HTTPManagerResponse) -> void:
	completed.emit(response)
	var listeners: Dictionary = get_meta("listeners", {})
	for key in listeners:
		if key == Listener.COMPLETE:
			listeners[key].call(response)
		elif key == Listener.SUCCESS:
			if response.successful:
				listeners[key].call(response)
		elif key == Listener.FAILURE:
			if not response.successful:
				listeners[key].call(response)

## Get endpoint uri with url params.
func get_parsed_uri() -> String:
	if route:
		return _parsed_uri
	return ""

func add_header(new_header: String) -> HTTPManagerRequest:
	headers.append(new_header)
	return self

#region Authentication
## Adds Basic Authentication header.
func set_basic_auth(username: String, password: String) -> HTTPManagerRequest:
	_set_auth("Basic " + Marshalls.utf8_to_base64(username + ":" + password))
	return self

## Adds Bearer Authentication header.
func set_bearer_auth(token: String) -> HTTPManagerRequest:
	_set_auth("Bearer " + token)
	return self

## Adds Basic Authentication header. Not implementet yet.
## @experimental
func set_diggest_auth(_username: String, _password: String) -> HTTPManagerRequest:
	push_error("Not implemented yet.")
	return self

## Adds Authorization header.
func _set_auth(type_credentials_string: String) -> void:
	headers.append("Authorization: " + type_credentials_string)
	use_auth = true
#endregion

## [method HTTPManager.create_request_from_route] calls this method to parse and
## add the url params.
func set_url_params(dict: Dictionary) -> Error:
	var parts := route.uri_pattern.split("/")
	var parsed_parts := PackedStringArray()
	var used_params := PackedStringArray()
	
	for part in parts:
		var parsed_part := ""
		if part in used_params:
			push_error("Duplicated url param. Use different names in 'uri_patern': ", route.resource_path)
			return FAILED
		elif part.begins_with("{"):
			if part.ends_with("?}"):
				part = part.substr(1, part.length() - 3)
				
				if not dict.has(part):
					continue
			elif part.ends_with("}"):
				part = part.substr(1, part.length() - 2)
				
				if not dict.has(part):
					push_error("Route requires '%s' param: %s" % [part, route.resource_path])
					return FAILED
			else:
				push_error("'{' does not close in 'uri_pattern': ", route.resource_path)
				return FAILED
			
			var dict_value = dict.get(part)
			used_params.append(part)
			dict.erase(part)
			
			if dict_value is int:
				parsed_part = str(parsed_part)
			elif dict_value is StringName or dict_value is String:
				parsed_part = String(dict_value)
			else:
				push_error("'%s' url param must be integer or string: %s" % [part, route.resource_path])
				return FAILED
		else:
			parsed_part = part
		parsed_parts.append(parsed_part)
	
	_parsed_uri = "/".join(parsed_parts) + route.client.parse_query(dict)
	
	return OK

## Formats and sets a body. See [method MIME.var_to_string].
func set_body(new_body, content_type := MIME.Type.NONE, attributes := {}) -> HTTPManagerRequest:
	if content_type != MIME.Type.NONE:
		for i in range(headers.size()):
			if headers[i].begins_with("Content-Type:"):
				headers.remove_at(i)
				break
		
		body = MIME.var_to_string(new_body, content_type)
		headers.append("Content-Type: " + MIME.type_to_string(content_type))
	elif new_body is String:
		body = new_body
	
	return self

## Starts request.
func start(listeners = {}) -> Error:
	if not http_manager:
		push_error("HTTPManager is disabled.")
		return FAILED
	
	if listeners is Callable:
		set_meta("listeners", {
			Listener.COMPLETE: listeners,
		})
	elif listeners is Array:
		var dict := {}
		var ls: int = listeners.size()
		if ls > 0:
			if listeners[0] is Callable:
				dict[Listener.SUCCESS] = listeners[0]
		if ls > 1:
			if listeners[1] is Callable:
				dict[Listener.FAILURE] = listeners[1]
	elif listeners is Dictionary:
		set_meta("listeners", listeners)
	
	return http_manager.request(self)
