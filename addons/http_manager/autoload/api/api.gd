class_name HTTPManagerAPI extends HTTPManagerAPIGroup

## HTTPManager API.
## 
## [b]Work in progress.[/b] This class is to extend it and define requests. An
## alternative to defining clients and routes via gdscript.
## 
## @experimental

## Checks if auth credentials are valid.
## @experimental
func auth_check() -> void:
	pass

## Creates a client.
## @experimental
func create_client(base_url: String) -> HTTPManagerClient:
	var c := HTTPManagerClient.new()
	c.base_url = base_url
	return c

## Creates a route.
## @experimental
func create_route(uri: String) -> HTTPManagerRoute:
	var r := HTTPManagerRoute.new()
	r.uri_pattern = uri
	return r

func _load_route(path: String) -> HTTPManagerRoute:
	return load(path)

#region Overridable Methods
## Returns API base dir, where files are stored. It must contain "routes"
## subfolder.
func _get_base_dir() -> String:
	return ""

## Returns API base URL. All routes are relative to this URL by default.
func _get_base_url() -> String:
	return ""
#endregion

#region Internal Methods
## Returns routes dir.
func _get_routes_dir() -> String:
	return _get_base_dir().path_join("routes")
#endregion
