class_name HTTPManagerAPI extends RefCounted

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

func _get_base_dir() -> String:
	return ""

func _request(route_filename: String, url_params := {}) -> HTTPManagerRequest:
	return (load(_get_base_dir().path_join(route_filename) + ".tres") as HTTPManagerRoute).create_request(url_params)

func _load_route(path: String) -> HTTPManagerRoute:
	return load(path)

func _auth_type() -> void:
	pass
