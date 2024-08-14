class_name HTTPOAuth2 extends RefCounted


var processing := false
var _redirect_server := TCPServer.new()
var _redirect_uri := ""


func process() -> void:
	if _redirect_server.is_connection_available():
		var connection := _redirect_server.take_connection()
		var request := connection.get_string(connection.get_available_bytes())
		if request:
			processing = false


func stop() -> void:
	_redirect_server.stop()
	processing = false


func start(port: int, bind_address := "*") -> Error:
	var error := _redirect_server.listen(port, bind_address)
	if error:
		return error
	
	processing = true
	
	return OK
