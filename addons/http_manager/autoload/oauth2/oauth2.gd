class_name OAuth2 extends Node


## OAuth 2.0 Local Redirect.
## 
## It starts local TCP server to handle a OAuth 2.0 redirect URI.
## 
## @tutorial(OAuth 2.0): https://datatracker.ietf.org/doc/html/rfc6749

## Setting name for default local server bind address.
const SETTING_NAME_BIND_ADDRESS := "addons/http_manager/auth/bind_address"
## Default local bind address.
const DEFAULT_BIND_ADDRESS := "127.0.0.1"
## Setting name for default local server port.
const SETTING_NAME_PORT := "addons/http_manager/auth/port"
## Default local server port.
const DEFAULT_PORT := 8120

## URI unreserved characters.
const UNRESERVED_CHARACTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"

## Request reference.
var request: HTTPManagerRequest
## Redirect TCP server.
var _redirect_server: TCPServer
## Loads local HTML file to display in the redirect URI: <bind_address>:<port>.
## See [method set_redirect_html].
var _redirect_html := ""
## Server duration.
var _duration := 120.0
## PKCE.
var _pkce: OAuth2PKCE
## State.
var _state := ""
## Current time. See [member duration].
var _time := 0.0
## Parsed redirect URI.
var _parsed_redirect_uri: HTTPManagerClientParsedUrl


func _process(delta: float) -> void:
	_time += delta
	if _time >= _duration:
		push_warning("OAuth 2.0 Timeout")
		var response := HTTPManagerResponse.new()
		response.successful = false
		request.complete(response)
		queue_free()
	elif _redirect_server.is_connection_available():
		var connection := _redirect_server.take_connection()
		var crequest := connection.get_string(connection.get_available_bytes())
		if not crequest.is_empty():
			if not _redirect_html.is_empty():
				connection.put_data("HTTP/1.1 200\r\n".to_ascii_buffer())
				connection.put_data(_redirect_html.to_ascii_buffer())
			
			var response := HTTPManagerResponse.new()
			response.headers.append(MIME.type_to_content_type(MIME.Type.TEXT))
			response.body = MIME.var_to_buffer(crequest, MIME.Type.TEXT)
			
			request.complete(response)
			queue_free()

#region Chain Methods
## Sets a HTML code to show in the redirect URI.
func set_redirect_html(html) -> OAuth2:
	if html is String:
		_redirect_html = html
	elif html is HTMLDocument:
		_redirect_html = html.text
	else:
		push_warning("'html' type is not valid.")
	return self

## Sets default redirect HTML code. See [methodd set_redirect_html] to set
## a custom code.
func set_default_redirect_html() -> OAuth2:
	set_redirect_html(HTMLDocument.new().add_doctype().start_html({
		lang = "en",
	}) \
		.start_head() \
			.add_meta({ charset = "UTF-8" }) \
		.close_tag() \
		.start_body() \
			.start_p() \
				.add_text("Hello world!") \
			.close_tag() \
		.close_tag() \
	.close_tag())
	
	return self

## Sets PKCE handler.
## @experimental
func set_pkce(code_key: String, code_length := 43, method := OAuth2PKCE.Method.S256) -> OAuth2:
	push_error("Not implemented.")
	return self

## Sets random state. Minimum length is 32.
func set_state(length := 100, param := "state") -> OAuth2:
	length = max(length, 32)
	_state = OAuth2.generate_state(length)
	request.parsed_url.query_param_join(param, _state)
	return self

## Sets redirect URI.
func set_redirect_uri(new_uri: String, param := "redirect_uri") -> OAuth2:
	_parsed_redirect_uri = HTTPManagerClient.parse_url(new_uri)
	if param != "":
		request.parsed_url.query_param_join(param, new_uri)
	return self
#endregion

func get_state() -> String:
	return _state

## Enables local server using [member _parsed_redirect_uri]. See 
## [method set_redirect_uri].
func set_server(enabled := true) -> OAuth2:
	_redirect_server = TCPServer.new() if enabled else null
	return self

## Starts the OAuth 2.0. Frees other [OAuth2].
func start(on_complete: Callable) -> Error:
	if not HTTPManagerRequest.http_manager:
		push_error("HTTPManager is not started.")
		queue_free()
		return FAILED
	
	# One OAuth 2.0
	for c in HTTPManagerRequest.http_manager.get_children():
		if c is OAuth2:
			c.queue_free()
	
	request.set_meta("listeners", { HTTPManagerRequest.Listener.COMPLETE: on_complete })
	
	var error := OK
	if _redirect_server:
		if not _parsed_redirect_uri:
			push_error("Redirect server requires non-null '_parsed_redirect_uri'.")
			return error
		
		var domain := _parsed_redirect_uri.domain
		if domain == "localhost": domain = "127.0.0.1"
		if not domain.is_valid_ip_address():
			push_error("Redirect server requires a domain as IP.")
			return error
		
		error = _redirect_server.listen(_parsed_redirect_uri.port, domain)
		if error:
			push_error("It cannot listen the port.")
			return error
	
	error = request.shell()
	if error:
		return error
	
	if _redirect_server:
		HTTPManagerRequest.http_manager.add_child(self)
	
	return OK

## Returns a random state string.
static func generate_state(length := 100) -> String:
	var s := ""
	var i := 0
	while i < length:
		s += UNRESERVED_CHARACTERS[randi_range(0, 65)]
		i += 1
	return s

## Returns a [OAuth2PKCE] object with random code verifier and code challenge.
static func generate_pkce(length := 43, method := OAuth2PKCE.Method.S256) -> OAuth2PKCE:
	var pkce := OAuth2PKCE.new()
	pkce.random()
	return pkce

## Returns default bind address.
static func get_default_bind_address() -> String:
	return ProjectSettings.get_setting(SETTING_NAME_BIND_ADDRESS, DEFAULT_BIND_ADDRESS)

## Returns default port.
static func get_default_port() -> int:
	return ProjectSettings.get_setting(SETTING_NAME_PORT, DEFAULT_PORT)
