class_name HTTPManagerServiceBranch extends HTTPManagerService


## Extends this class to split routes with a prefix relative to base url.
## @experimental

var _service: HTTPManagerService
var _prefix := ""

## [param prefix] is a path prefix for endpoints.
func _init(service: HTTPManagerService, prefix := "") -> void:
	_service = service
	_prefix = prefix


func _base_url() -> String:
	return _service.get_url(_prefix)
