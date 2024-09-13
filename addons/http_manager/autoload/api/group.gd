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

var _weak_parent: HTTPManagerAPIGroup
var _current_request: HTTPManagerRequest

func _init(parent: HTTPManagerAPIGroup = null) -> void:
	_weak_parent = weakref(parent)

#region Overridable Methods
## Route path prefix.
## @experimental
func _prefix() -> String:
	return ""
#endregion

## Returns a new request using a route filename relative to routes dir from
## [method _get_base_dir()]. Do not add ".tres".
func _request(route_filename := "", url_params := {}) -> HTTPManagerRequest:
	if route_filename == "":
		var request := _current_request
		_current_request = null
		return request
	
	var route_path := _get_routes_dir().path_join(route_filename) + ".tres"
	var route := load(route_path) as HTTPManagerRoute
	return route.create_request(url_params)

## Creates a route.
## @experimental
func _route(path: String, method: HTTPClient.Method, params := {}) -> HTTPManagerRequest:
	var route := HTTPManagerRoute.new()
	route.uri_pattern = path
	route.method = HTTPManagerRoute.Method.values()[method]
	
	_current_request = HTTPManagerRequest.new()
	_current_request.route = route
	_current_request.set_url_params(params)
	_current_request.parsed_url = _parse_path(path)
	
	return _current_request

## Creates a route with get method.
func _route_get(path: String, params := {}) -> HTTPManagerRequest:
	return _route(path, HTTPClient.METHOD_GET, params)

## Creates a route with post method.
func _route_post(path: String, params := {}) -> HTTPManagerRequest:
	return _route(path, HTTPClient.METHOD_POST, params)

## Creates a route with put method.
func _route_put(path: String, params := {}) -> HTTPManagerRequest:
	return _route(path, HTTPClient.METHOD_PUT, params)

## Creates a route with patch method.
func _route_patch(path: String, params := {}) -> HTTPManagerRequest:
	return _route(path, HTTPClient.METHOD_PATCH, params)

## Creates a route with delete method.
func _route_delete(path: String, params := {}) -> HTTPManagerRequest:
	return _route(path, HTTPClient.METHOD_DELETE, params)

#region Internal Methods
## @experimental
func _parse_path(path: String) -> HTTPManagerClientParsedUrl:
	return HTTPManagerClient.parse_url(path)

## Returns routes dir path.
func _get_routes_dir() -> String:
	return (get_script() as GDScript).resource_path.get_base_dir()
#endregion
