class_name HTTPOAuth2 extends Node


## OAuth 2.0 Local Redirect.
## 
## It starts TCP server to handle a local OAuth 2.0 redirect URI.

enum PCKEMethod {
	PLAIN,
	S256,
}

enum PCKECode {
	VERIFIER,
	CHALLENGE,
}

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


func set_redirect_html(redirect_html: String) -> HTTPOAuth2:
	_redirect_html = redirect_html
	return self

## Starts the OAuth 2.0. Frees other HTTPOAuth2.
func start(on_complete = null) -> Error:
	if not HTTPManagerRequest.http_manager:
		push_error("HTTPManager is not started.")
		queue_free()
		return FAILED
	
	# One OAuth 2.0
	for c in HTTPManagerRequest.http_manager.get_children():
		if c is HTTPOAuth2:
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


## Generates a random PCKE code verifier.
## [b]ASCII:[/b] 45: -, 46: ., 48-57: 0-9, 65-90: A-Z, 95: _, 97-122: a-z, 126: ~
static func pcke_codes(length := 43, method := PCKEMethod.S256) -> Dictionary:
	var s := ""
	length = clamp(length, 43, 128)
	
	var i := 0
	while i < length:
		var ci := randi_range(0, 65)
		if ci < 2:
			ci += 45
		elif ci < 12:
			ci += 46
		elif ci < 38:
			ci += 53
		elif ci == 38:
			ci = 95
		elif ci < 65:
			ci += 58
		else:
			ci = 126
		s += char(ci)
		i += 1
	
	return {
		PCKECode.VERIFIER: s,
		PCKECode.CHALLENGE: Marshalls.utf8_to_base64(s.sha256_text()) if method == PCKEMethod.S256 else s,
	}


static func pcke_method_to_string(method: PCKEMethod) -> String:
	if method == PCKEMethod.S256:
		return "S256"
	
	if method == PCKEMethod.PLAIN:
		return "plain"
	
	return ""
