class_name HTTPManagerAPIGroup extends RefCounted

## @experimental


#region Overridable Methods
## Routes prefix. It does not need left or right "/".
## @experimental
func _get_prefix() -> String:
	return ""

## Returns routes dir path.
func _get_routes_dir() -> String:
	return ""

## Returns a new request using a route filename relative to routes dir from
## [method _get_base_dir()]. Do not add ".tres".
## @deprecated
func _request(route_filename: String, url_params := {}) -> HTTPManagerRequest:
	return (load(_get_routes_dir().path_join(route_filename) + ".tres") as HTTPManagerRoute).create_request(url_params)
#endregion
