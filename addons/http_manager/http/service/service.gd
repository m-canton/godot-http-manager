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


func _default_auth() -> Array[HTTPManagerAuth]:
	return []


func _default_oauth_config() -> HTTPManagerOAuthConfig:
	return null
#endregion

func get_url(path: String) -> void:
	return _base_url().path_join(path)

## Sets authentication credentials in the current request. It uses authenticator from
## [method _default_auth] if [param authenticators] is empty.
func authorize(auths: Array[HTTPManagerAuth] = []) -> Error:
	if auths.is_empty():
		auths = _default_auth()
	
	for a in auths:
		var r := a.handle(_current_request)
		if r:
			r.start()
	
	return OK
