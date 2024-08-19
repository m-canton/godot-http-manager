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
var _body = null
## Body MIME type.
var _body_type := MIME.Type.NONE
## Body MIME type attributes. Example: [code]{"charset": "UFT-8"}[/code].
var _body_attributes := {}
## Mode.
var mode := Mode.DEFAULT
## Indicates if this request is valid.
var valid := true
## Parsed URL.
var parsed_url: HTTPManagerClientParsedUrl

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

## Returns the current body.
func get_body() -> Variant:
	return _body

## Returns body as [String].
func get_body_as_string() -> String:
	if _body_type == MIME.Type.URL_ENCODED:
		return _get_urlencoded_body_string()
	return MIME.var_to_string(_body, _body_type, _body_attributes)

## Returns body as [PackedByteArray].
func get_body_as_buffer() -> PackedByteArray:
	if _body_type == MIME.Type.URL_ENCODED:
		return _get_urlencoded_body_string().to_utf8_buffer()
	return MIME.var_to_buffer(_body, _body_type, _body_attributes)

func _get_urlencoded_body_string() -> String:
	if _body is String:
		return _body
	
	if route and route.client:
		return route.client.query_string_from_dict(_body) if _body is Dictionary else str(_body)
	
	push_error("'URL_ENCODED' requires client.")
	return ""

#region Authorization
## Adds Basic Authentication header.
func set_basic_auth(username: String, password := "") -> HTTPManagerRequest:
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

#region Chain Methods
## Adds a new header.
func add_header(new_header: String) -> HTTPManagerRequest:
	headers.append(new_header)
	return self

## Formats and sets a body. See [method MIME.var_to_string].
func set_body(new_body, new_content_type := MIME.Type.NONE, new_attributes := {}) -> HTTPManagerRequest:
	if route and route.method == HTTPManagerRoute.Method.GET:
		push_error("GET request cannot set body.")
		return self
	
	_body_type = new_content_type
	_body_attributes = new_attributes
	
	var ct_found := false
	for i in range(headers.size()):
		if headers[i].begins_with("Content-Type:"):
			if _body_type == MIME.Type.NONE:
				headers.remove_at(i)
			else:
				headers[i] = MIME.type_to_content_type(_body_type, _body_attributes)
			ct_found = true
			break
	
	if not ct_found and _body_type != MIME.Type.NONE:
		headers.append(MIME.type_to_content_type(_body_type, _body_attributes))
	
	_body = new_body
	
	return self

func merge_body(new_body: Dictionary, overwrite := true) -> HTTPManagerRequest:
	if _body is Dictionary:
		_body.merge(new_body, overwrite)
	return self

func set_tls_options(new_tls_options: TLSOptions) -> HTTPManagerRequest:
	tls_options = new_tls_options
	return self
#endregion

## [method HTTPManagerRoute.create_request] calls this method to parse and
## set the url params.
func set_url_params(new_params: Dictionary) -> Error:
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
				
				if not new_params.has(part):
					continue
			elif part.ends_with("}"):
				part = part.substr(1, part.length() - 2)
				
				if not new_params.has(part):
					push_error("Route requires '%s' param: %s" % [part, route.resource_path])
					return FAILED
			else:
				push_error("'{' does not close in 'uri_pattern': ", route.resource_path)
				return FAILED
			
			var param_value = new_params.get(part)
			used_params.append(part)
			new_params.erase(part)
			
			if param_value is int:
				parsed_part = str(parsed_part)
			elif param_value is StringName or param_value is String:
				parsed_part = String(param_value)
			else:
				push_error("'%s' url param must be integer or string: %s" % [part, route.resource_path])
				return FAILED
		else:
			parsed_part = part
		parsed_parts.append(parsed_part)
	
	parsed_url = route.client.parse_base_url()
	if parsed_url == null:
		push_error("Parsed URL is null.")
		valid = false
		return FAILED
	
	if parsed_url.path != "" and parsed_url.path.ends_with("/"):
		push_error("Base URL cannot end with '/'.")
		valid = false
		return FAILED
	
	var subpath := "/".join(parsed_parts)
	if not subpath.begins_with("/"):
		push_error("Route must start with '/'.")
	parsed_url.path += subpath
	parsed_url.set_query(route.client.query_string_from_dict(new_params))
	
	return OK

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

## Creates a [OAuth2] with this request.
func oauth2() -> OAuth2:
	var oa := OAuth2.new()
	oa.request = self
	return oa

## Requests the OS to open URL. See [method OS.shell_open].
func shell() -> Error:
	var url := parsed_url.get_url()
	if url.is_empty():
		push_error("URL is not valid.")
		return FAILED
	
	return OS.shell_open(url)
