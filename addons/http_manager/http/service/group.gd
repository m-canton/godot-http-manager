class_name HTTPManagerServiceGroup extends RefCounted


## Extends this class to split routes with a prefix relative to base url.

var _service: HTTPManagerService


func _init(service: HTTPManagerService) -> void:
	_service = service


func get_url(path: String) -> void:
	if _service:
		_service.get_url(_prefix().path_join(path))


#region Overrideable Methods
## Returns group prefix.
func _prefix() -> String:
	if _service:
		var script_dir := (get_script() as Script).resource_path.get_base_dir()
		var service_script_dir := (_service.get_script() as Script) \
				.resource_path.get_base_dir()
		return script_dir.trim_prefix(service_script_dir)
	return ""
#endregion
