class_name HTTPManagerAPIGroup extends RefCounted

## HTTPManager API Group
## 
## API Groups is used to split routes in multiple scripts. You can define a
## global prefix to add it to parent URL.
## 
## [codeblock]
## # groups/posts.gd
## extends HTTPManagerAPIGroup
##
## func _prefix() -> String:
##     return "posts"
## 
## # api.gd
## extends HTTPManagerAPI
## 
## var posts := preload("res://http/myapi/groups/posts.gd").new(self)
## 
## # Scene script.
## var _api := preload("res://http/myapi/api.gd")
## 
## _api.posts.search("query").start() # Names are autocompleted
## [/codeblock]

## Parent [WeakRef].
var _weak_parent: WeakRef
## Current request created with [method _route].
var _current_request: HTTPManagerRequest

## Pass [HTTPManagerAPIGroup] as parent. Ensure root is [HTTPManagerAPI] with
## a base URL.
func _init(parent: HTTPManagerAPIGroup) -> void:
	_weak_parent = weakref(parent)

#region Protected Methods
func _oauth2_check() -> bool:
	return false

## Returns prefix.
func _prefix() -> String:
	return ""

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
	_current_request = create_route(path, method).create_request(params)
	
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
#endregion

#region Private Methods
## @experimental
func _parse_path(path: String) -> HTTPManagerClientParsedUrl:
	return HTTPManagerClient.parse_url(path)

## Returns routes dir path.
func _get_routes_dir() -> String:
	return (get_script() as GDScript).resource_path.get_base_dir()

func create_route(path: String, method: HTTPClient.Method) -> HTTPManagerRoute:
	if _weak_parent:
		return (_weak_parent.get_ref() as HTTPManagerAPIGroup) \
				.create_route(_prefix().path_join(path), method)
	return null
#endregion
