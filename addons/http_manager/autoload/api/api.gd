class_name HTTPManagerAPI extends HTTPManagerAPIGroup

## HTTPManager API.
## 
## This class is to extend it and define requests. After
## you can load relative route files with [method HTTPManagerAPIGroup._request].
## 
## @experimental

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

## Checks if auth credentials are valid.
## @experimental
func auth_check() -> void:
	pass

## Creates a client.
## @deprecated
func create_client(base_url: String) -> HTTPManagerClient:
	var c := HTTPManagerClient.new()
	c.base_url = base_url
	return c

## Creates a route.
## @deprecated
func create_route(uri: String) -> HTTPManagerRoute:
	var r := HTTPManagerRoute.new()
	r.uri_pattern = uri
	return r

#region Internal Methods
## Returns routes dir.
func _get_routes_dir() -> String:
	return _get_base_dir().path_join("routes")
#endregion
