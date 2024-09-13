class_name HTTPManagerRequest extends HTTPManagerStream

signal completed(response: HTTPManagerResponse)

static var http_manager: Node

## HTTPManager Request class.
## 
## This class requests from a [HTTPManagerRoute] according to client
## restrictions. Use [method create_from_route] to create a instance because
## it adds the client and route headers to this and sets the route for you.

enum Listener {
	COMPLETE,
	SUCCESS,
	FAILURE,
}

## Route resource.
var route: HTTPManagerRoute
## Overrides route priority. See [HTTPManagerRoute.priority].
var priority := -1
## Body.
var _body = null
## Body MIME type.
var _body_type := MIME.Type.NONE
## Body MIME type attributes. Example: [code]{"charset": "UFT-8"}[/code].
var _body_attributes := {}
## Indicates if this request is valid. This prevents null objects in chain
## methods. It will return an error when starting the request.
var valid := true
## Parsed URL.
var parsed_url: HTTPManagerClientParsedUrl

## TLS Options.
var tls_options: TLSOptions

## Emits [signal completed] signal with the response. Used by HTTPManager when
## response is completed or gets a error.
func complete(response: HTTPManagerResponse) -> void:
	completed.emit(response)
	var listeners: Dictionary = get_meta(&"listeners", {})
	for key in listeners:
		var callable = null
		if key == Listener.COMPLETE:
			callable = listeners[key]
		elif key == Listener.SUCCESS:
			if response.successful:
				callable = listeners[key]
		elif key == Listener.FAILURE:
			if not response.successful:
				callable = listeners[key]
		if callable is Callable and callable.is_valid():
			callable.call(response)

## Do not call this method. It saves OAuth 2.0 tokens and starts the pending
## request.
func complete_with_auth2_token(response: HTTPManagerResponse) -> void:
	var error := route.client.data.save_oauth2_token_from_response(response)
	if error:
		push_error("It cannot start the pending request. OAuth2 Token Save Error.")
		return
	
	start()

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
	return _set_auth("Basic " + Marshalls.utf8_to_base64(username + ":" + password))

## Adds Bearer Authentication header.
func set_bearer_auth(token: String) -> HTTPManagerRequest:
	return _set_auth("Bearer " + token)

## Adds Basic Authentication header. Not implementet yet.
## @experimental
func set_diggest_auth(_username: String, _password: String) -> HTTPManagerRequest:
	push_error("Not implemented yet.")
	return self

## Adds Authorization header.
func _set_auth(auth_value: String) -> HTTPManagerRequest:
	add_header("Authorization: " + auth_value)
	return self
#endregion

#region Chain Methods
## See [method HTTPManagerStream].
func add_header(new_header: String) -> HTTPManagerRequest:
	return super(new_header)

## Sets accept header as a MIME type. If you need more types, use
## [method add_header] instead.
func accept(type: MIME.Type, attributes := {}) -> HTTPManagerRequest:
	add_header(MIME.type_to_accept(type, attributes))
	return self

## Sets accept header as JSON.
func accept_json() -> HTTPManagerRequest:
	add_header(MIME.type_to_accept(MIME.Type.JSON))
	return self

## Sets accept header as XML.
func accept_xml() -> HTTPManagerRequest:
	add_header(MIME.type_to_accept(MIME.Type.XML))
	return self

## Sets body. [HTTPManager] uses [method MIME.var_to_string] to convert it.
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

## Sets body as JSON. [param new_body] must be [Array] or [Dictionary].
func set_json_body(new_body) -> HTTPManagerRequest:
	return set_body(new_body, MIME.Type.JSON)

## Sets body as URL ENCODED.
func set_urlencoded_body(new_body: Dictionary) -> HTTPManagerRequest:
	return set_body(new_body, MIME.Type.URL_ENCODED)

## Merges body if current body is [Dictionary]. Useful for JSON and URL ENCODED
## bodies.
func merge_body(new_body: Dictionary, overwrite := true) -> HTTPManagerRequest:
	if _body is Dictionary:
		_body.merge(new_body, overwrite)
	return self

## Sets TLS options.
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
				parsed_part = str(param_value)
			elif param_value is StringName or param_value is String:
				parsed_part = String(param_value)
			else:
				push_error("'%s' URL param must be integer or string: %s" % [part, route.resource_path])
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
func start(listeners = null) -> Error:
	if not http_manager:
		push_error("HTTPManager is disabled.")
		return FAILED
	
	if listeners != null:
		set_meta(&"listeners", create_listeners_dict(listeners))
	
	if not valid:
		var response := HTTPManagerResponse.new()
		response.successful = false
		response.body = "No Valid Request.".to_ascii_buffer()
		response.headers.append(MIME.type_to_content_type(MIME.Type.TEXT))
		complete(response)
		return FAILED
	
	if route.auth_type == HTTPManagerRoute.AuthType.TOKEN_CHECK:
		return OAuth2.check(self)
	elif route.auth_type == HTTPManagerRoute.AuthType.API_KEY_CHECK:
		parsed_url.query_param_join("key", route.auth_route.client.data.get_api_key())
	
	return http_manager.start_request(self)

## Async request to use with await.
func start_await(r: HTTPManagerRequest) -> Variant:
	if r.start() == OK:
		var response: HTTPManagerResponse = await r.completed
		if response.successful:
			return response.parse()
		else:
			return null
	return null

## Creates a [OAuth2] with this request. Adds the following query params using
## [member route].client.data: response_type, redirect_uri and client_id.
func oauth2() -> OAuth2:
	var oa := OAuth2.new()
	oa.request = self
	
	if valid:
		var data := route.client.data
		if data:
			var client_id := data.get_client_id()
			if client_id.is_empty():
				push_error("Invalid OAuth 2.0 request: 'client.data' is null.")
				valid = false
			elif route.auth_type != HTTPManagerRoute.AuthType.OAUTH2_CODE:
				push_error("Invalid OAuth 2.0 request: 'route.auth_type' must be OAuth 2.0 Authorization Code type.")
				valid = false
			else:
				parsed_url.merge_query({
					response_type = "code",
					redirect_uri = OAuth2.get_local_server_redirect_uri(data.subpath),
					client_id = data.get_client_id(),
				})
		else:
			push_error("Invalid OAuth 2.0 request: 'route.client.data' is null.")
	
	return oa

## Requests OS to open URL. See [method OS.shell_open].
func shell() -> Error:
	var url := parsed_url.get_url()
	if url.is_empty():
		push_error("URL is not valid.")
		return FAILED
	
	return OS.shell_open(url)

## Parses a request string from local server.
static func parse_string(text: String) -> HTTPManagerRequest:
	var lines := text.replace("\r\n", "\n").split("\n", false)
	if lines.size() < 2:
		push_error("It needs 2 lines to parse.")
		return null
	
	var l0 := lines[0].split(" ", false)
	var l1 := lines[1].trim_prefix("Host: ")
	lines = lines.slice(2)
	
	if l0.size() != 3:
		push_error("Line 0 is not valid: ", l0)
		return null
	
	if l0[2] != "HTTP/1.1":
		push_error("It only supports HTTP/1.1: ", l0)
		return null
	
	if not l0[1].begins_with("/"):
		push_error("URL path must start with '/': ", l0)
		return null
	
	var r := HTTPManagerRequest.new()
	r.parsed_url = HTTPManagerClient.parse_url("http://" + l1 + l0[1])
	if not r.parsed_url:
		push_error("Request URL is not valid.")
		return null
	
	r.route = HTTPManagerRoute.new()
	r.route.method = HTTPManagerRoute.Method.get(l0[0])
	
	for line in lines:
		r.add_header(line)
	
	return r

## Used by [HTTPManagerRequest] and [HTTPManagerDownload] to set on complete
## listeners.
## @experimental
static func create_listeners_dict(listeners) -> Dictionary:
	var dict := {}
	if listeners is Callable:
		dict[Listener.COMPLETE] = listeners
	elif listeners is Array:
		listeners.resize(2)
		if listeners[0] is Callable:
			dict[Listener.SUCCESS] = listeners[0]
		if listeners[1] is Callable:
			dict[Listener.FAILURE] = listeners[1]
	elif listeners is Dictionary:
		dict = listeners
	elif listeners == null:
		pass
	else:
		push_warning("Invalid 'listeners' type.")
	return dict
