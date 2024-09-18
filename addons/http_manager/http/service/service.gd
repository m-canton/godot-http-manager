class_name HTTPManagerService extends RefCounted


var _current_request: HTTPManagerRequest

#region Overrideable Methods
func _base_url() -> String:
	return ""


func _default_auth() -> Array[HTTPManagerAuthenticator]:
	return []


func _default_oauth_config() -> HTTPManagerServiceOAuthConfig:
	return null
#endregion

## Sets authentication credentials in the current request. It uses authenticator from
## [method _default_auth] if [param authenticators] is empty.
func authenticate(authenticators: Array[HTTPManagerAuthenticator] = []) -> Error:
	if authenticators.is_empty():
		authenticators = _default_auth()
	
	for a in authenticators:
		a.handle(_current_request)
	
	return OK
