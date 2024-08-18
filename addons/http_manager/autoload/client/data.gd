class_name HTTPManagerClientData extends RefCounted

## @experimental

var _path := ""
var _file := ConfigFile.new()


func get_access_token() -> String:
	return _file.get_value("token", "access_token", "")


func get_refresh_token() -> String:
	return _file.get_value("token", "refresh_token", "")


func save_token(dict: Dictionary) -> Error:
	for key in dict:
		_file.set_value("token", key, dict[key])
	return save()


func save(new_key := "") -> Error:
	return _file.save(_path) if new_key.is_empty() else _change_key(new_key)


func _change_key(new_key: String) -> Error:
	if new_key.is_empty():
		push_error("'new_key' cannot be empty.")
		return FAILED
	
	var new_path := HTTPManagerClient.get_clients_dir().path_join(new_key)
	var error := _file.save(new_path)
	if error:
		push_error(error_string(error))
		return error
	
	_path = new_path
	
	error = DirAccess.remove_absolute(_path)
	if error:
		push_error(error_string(error))
	
	return OK


static func load_from_file(key: String) -> HTTPManagerClientData:
	if key.is_empty():
		push_error("'key' cannot be empty.")
		return null
	
	var data := HTTPManagerClientData.new()
	data._path = HTTPManagerClient.get_clients_dir().path_join(key)
	data._file.load(data._path)
	return data
