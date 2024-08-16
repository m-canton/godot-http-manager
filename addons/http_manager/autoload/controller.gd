class_name HTTPManagerController extends RefCounted

## HTTPManager Controller.
## 
## [b]Work in progress.[/b] This class is to extend it and define routes to
## request them. An alternative to defining clients and routes via gdscript.
## 
## @experimental


func create_client(base_url: String) -> HTTPManagerClient:
	var c := HTTPManagerClient.new()
	c.base_url = base_url
	return c


func create_route(uri: String) -> HTTPManagerRoute:
	var r := HTTPManagerRoute.new()
	r.uri_pattern = uri
	return r
