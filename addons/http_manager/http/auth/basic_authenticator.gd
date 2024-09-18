class_name HTTPManagerBasicAuthenticator extends HTTPManagerAuthenticator


var token := ""


func handle(request: HTTPManagerRequest) -> HTTPManagerRequest:
	request.set_header()
	return null
