class_name HTTPManagerBasicAuthenticator extends HTTPManagerAuthenticator


var token := ""


func handle(request: HTTPManagerRequest) -> void:
	request.set_header()
