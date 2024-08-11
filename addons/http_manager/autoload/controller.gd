class_name HTTPManagerController extends RefCounted

## HTTPManager Controller.
## 
## [b]Work in progress.[/b] This class is to extend it and define routes to
## request them.
## 
## @experimental


var _client: HTTPManagerClient


func set_client(client: HTTPManagerClient) -> void:
	_client = client


func set_route() -> void:
	pass
