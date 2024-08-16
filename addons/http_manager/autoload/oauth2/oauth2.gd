class_name OAuth2 extends Node


## OAuth 2.0 Local Redirect.
## 
## It starts TCP server to handle a local OAuth 2.0 redirect URI.
## 
## @tutorial(OAuth 2.0): https://datatracker.ietf.org/doc/html/rfc6749

## Request reference.
var request: HTTPManagerRequest
## Server port.
var port := 0
## Server address.
var bind_address := "*"
## Redirect TCP server.
var _redirect_server := TCPServer.new()
## Loads local HTML file to display in the redirect URI: <bind_address>:<port>
var _redirect_html := ""
## Timeout
var _duration := 120.0
## Current time
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

func set_redirect_html(redirect_html: String) -> OAuth2:
	_redirect_html = redirect_html
	return self

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

func set_pkce(code_key: String, code_length := 43, method := OAuth2PKCE.Method.S256) -> OAuth2:
	push_error("Not implemented.")
	return self

## Starts the OAuth 2.0. Frees other [OAuth2].
func start(on_complete = null) -> Error:
	if not HTTPManagerRequest.http_manager:
		push_error("HTTPManager is not started.")
		queue_free()
		return FAILED
	
	# One OAuth 2.0
	for c in HTTPManagerRequest.http_manager.get_children():
		if c is OAuth2:
			c.queue_free()
	
	HTTPManagerRequest.http_manager.add_child(self)
	
	if on_complete is Callable:
		request.set_meta("listeners", { HTTPManagerRequest.Listener.COMPLETE: on_complete })
	
	var error := _redirect_server.listen(port, bind_address)
	if error:
		push_error("It cannot listen the port.")
		queue_free()
		return error
	
	error = request.shell()
	if error:
		queue_free()
		return error
	
	return OK
