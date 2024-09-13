class_name HTTPManagerAPI extends HTTPManagerAPIGroup

## HTTPManager API.
## 
## This class is to extend it and define requests. After
## you can load relative route files with [method HTTPManagerAPIGroup._request].
## 
## @experimental

var _client: HTTPManagerClient

## Override this method and use [method _create_client] to set a client.
func _init() -> void:
	pass

#region Overridable Methods
## Returns API base dir, where files are stored. It must contain "routes"
## subfolder.
func _get_base_dir() -> String:
	return (get_script() as GDScript).resource_path.get_base_dir()

## Returns API base URL. All routes are relative to this URL by default.
## @deprecated
func _get_base_url() -> String:
	return ""
#endregion

## Creates a client.
func _define_client(path: String, base_url: String) -> HTTPManagerClient:
	_client = HTTPManagerClient.new()
	_client.base_url = base_url
	
	_client.data = HTTPManagerClientData.new()
	_client.data.path = path
	return _client

## Checks if auth credentials are valid.
## @experimental
func auth_check() -> void:
	pass

#region Private Methods
## Creates a route.
func create_route(path: String, method: HTTPClient.Method) -> HTTPManagerRoute:
	if not _client:
		push_error("No client.")
		return null
	
	var route := HTTPManagerRoute.new()
	route.client = _client
	route.uri_pattern = path
	route.method = HTTPManagerRoute.Method.values()[method]
	return route

## Returns routes dir.
func _get_routes_dir() -> String:
	return _get_base_dir().path_join("routes")
#endregion
