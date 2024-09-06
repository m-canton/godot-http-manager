class_name HTTPManagerAPIGroup extends RefCounted

## HTTPManager API Group
## 
## Using a routes subfolder, it creates an API route group.
## [codeblock]
## # Main api.gd
## var posts := preload("res://http/myapi/routes/posts/api.gd").new()
## 
## # Scene script.
## var _api := preload("res://http/myapi/api.gd")
## 
## _api.posts.search("query").start()
## [/codeblock]
## @experimental


#region Overridable Methods
## Routes prefix. It does not need left or right "/".
## @experimental
func _get_prefix() -> String:
	return ""

## Returns routes dir path.
func _get_routes_dir() -> String:
	return (get_script() as GDScript).resource_path.get_base_dir()
#endregion

## Returns a new request using a route filename relative to routes dir from
## [method _get_base_dir()]. Do not add ".tres".
## @deprecated
func _request(route_filename: String, url_params := {}) -> HTTPManagerRequest:
	var route_path := _get_routes_dir().path_join(route_filename) + ".tres"
	var route := load(route_path) as HTTPManagerRoute
	return route.create_request(url_params)
