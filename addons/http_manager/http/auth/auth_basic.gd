class_name HTTPManagerAuthBasic extends HTTPManagerAuth


var username := ""
var password := ""


func handle(request: HTTPManagerRequest) -> HTTPManagerRequest:
	request.set_basic_auth("username", "password")
	return null
