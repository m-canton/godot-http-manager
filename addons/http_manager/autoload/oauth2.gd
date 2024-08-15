class_name HTTPOAuth2 extends Resource


enum PCKEMethod {
	PLAIN,
	S256,
}

var processing := false
var weak_request: WeakRef
var port := 0
var bind_address := "*"
var _redirect_server := TCPServer.new()
var _redirect_uri := ""
## Loads local HTML file to display in the redirect URI: <bind_address>:<port>
var _redirect_html_path := ""


func _init(new_port: int, new_bind_address: String) -> void:
	port = new_port
	bind_address = new_bind_address


func process() -> void:
	if _redirect_server.is_connection_available():
		var connection := _redirect_server.take_connection()
		var request := connection.get_string(connection.get_available_bytes())
		if request:
			var bytes := FileAccess.get_file_as_bytes(_redirect_html_path)
			if not bytes.is_empty():
				connection.put_data("HTTP/1.1 200\r\n".to_ascii_buffer())
				connection.put_data(bytes)
			processing = false


func stop() -> void:
	_redirect_server.stop()
	processing = false


func start() -> Error:
	var error := _redirect_server.listen(port, bind_address)
	if error:
		return error
	
	processing = true
	
	var request: HTTPManagerRequest = weak_request.get_ref()
	return request.start()


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
	
	if method == PCKEMethod.S256:
		return {
			verifier = s,
			challenge = Marshalls.utf8_to_base64(s.sha256_text()),
		}
	else:
		return { verifier = s }
