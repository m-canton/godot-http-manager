class_name HTTPManagerServiceGroup extends RefCounted


## Extends this class to split routes with a prefix relative to base url.

var _service: HTTPManagerService


func _init(service: HTTPManagerService) -> void:
	_service = service


#region Overrideable Methods
## Returns group prefix.
func _prefix() -> String:
	return ""
#endregion
