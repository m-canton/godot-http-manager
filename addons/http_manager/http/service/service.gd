class_name HTTPManagerService extends RefCounted

## Define a API wrapper extending this class. Create methods which return
## requests to start anywhere.[br]
## To split routes, you can extend [HTTPManagerServiceGroup] class. After you
## define a method that returns this class and set your service. You can use
## [code]class_name[/code] to get autocompletion in your scripts.

var _current_request: HTTPManagerRequest

#region Overrideable Methods
func _base_url() -> String:
	return ""


func _default_auth() -> Array[HTTPManagerAuthenticator]:
	return []


func _default_oauth_config() -> HTTPManagerServiceOAuthConfig:
	return null
#endregion

func get_url(path: String) -> void:
	return _base_url().path_join(path)

## Sets authentication credentials in the current request. It uses authenticator from
## [method _default_auth] if [param authenticators] is empty.
func authenticate(authenticators: Array[HTTPManagerAuthenticator] = []) -> Error:
	if authenticators.is_empty():
		authenticators = _default_auth()
	
	for a in authenticators:
		a.handle(_current_request)
	
	return OK
