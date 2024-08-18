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
## Server port.
var _port := 0
## Server address.
var _bind_address := ""
## Redirect TCP server.
var _redirect_server := TCPServer.new()
## Loads local HTML file to display in the redirect URI: <bind_address>:<port>.
## See [method set_redirect_html].
var _redirect_html := ""
## Server duration.
var _duration := 120.0
## Current time. See [member duration].
var _time := 0.0


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

## Sets a HTML code to show in the redirect URI.
func set_redirect_html(redirect_html: String) -> OAuth2:
	_redirect_html = redirect_html
	return self

## Sets default redirect HTML code. See [methodd set_redirect_html] to set
## a custom code.
func set_default_redirect_html() -> OAuth2:
	_redirect_html = HTMLDocument.new().add_doctype().start_html({
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
	.close_tag().text
	
	return self

## Sets PKCE handler.
## @experimental
func set_pkce(code_key: String, code_length := 43, method := OAuth2PKCE.Method.S256) -> OAuth2:
	push_error("Not implemented.")
	return self

## Sets local server port and bind address. See [method TCPServer.listen]
func set_server(port := 0, bind_address := "") -> void:
	_bind_address = OAuth2.get_default_bind_address() if bind_address == "" else bind_address
	_port = OAuth2.get_default_port() if port == 0 else port

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
	
	var error := _redirect_server.listen(_port, _bind_address)
	if error:
		push_error("It cannot listen the port.")
		return error
	
	error = request.shell()
	if error:
		return error
	
	HTTPManagerRequest.http_manager.add_child(self)
	
	return OK


static func generate_state(length := 50) -> String:
	var s := ""
	var i := 0
	while i < length:
		s += UNRESERVED_CHARACTERS[randi_range(0, 65)]
		i += 1
	return s


static func get_default_bind_address() -> String:
	return ProjectSettings.get_setting(SETTING_NAME_BIND_ADDRESS, DEFAULT_BIND_ADDRESS)


static func get_default_port() -> int:
	return ProjectSettings.get_setting(SETTING_NAME_PORT, DEFAULT_PORT)
