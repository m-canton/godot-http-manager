class_name HTTPManagerClientData extends Resource

## @experimental

## Client data dir path relative to [method HTTPManagerClient.get_clients_dir()].
@export var subpath := ""

## Client data dir path.
var _dir_path := ""
## Client data file.
var _file: ConfigFile
## Client data file path.
var _file_path := ""
## Client data load error.
var _load_error := FAILED

## Returns client ID.
func get_client_id() -> String:
	_ensure_file()
	return _file.get_value("client", "id", "")

## Returns client secret.
func get_client_secret() -> String:
	_ensure_file()
	return _file.get_value("client", "secret", "")

## Returns API key.
func get_api_key() -> String:
	_ensure_file()
	return _file.get_value("api", "key", "")

## Returns OAuth 2.0 access token.
func get_access_token() -> String:
	_ensure_file()
	return _file.get_value("token", "access_token", "")

## Returns OAuth 2.0 refresh token.
func get_refresh_token() -> String:
	_ensure_file()
	return _file.get_value("token", "refresh_token", "")

## Returns OAuth 2.0 expiration time.
func get_expiration_time() -> int:
	_ensure_file()
	return _file.get_value("token", "expires_in", 0)

## Returns OAuth 2.0 token type.
func get_token_type() -> String:
	_ensure_file()
	return _file.get_value("token", "token_type", "")

## Returns token section as [Dictionary].
func get_token_dict() -> Dictionary:
	_ensure_file()
	if not _file.has_section("token"):
		return {}
	
	var dict := {}
	for key in _file.get_section_keys("token"):
		dict[key] = _file.get_value("token", key)
	return dict

## Returns [code]true[/code] if OAuth 2.0 token is valid.
func check_token() -> bool:
	_ensure_file()
	return _file.get_value("token", "expires_in", 0) > Time.get_unix_time_from_system()

## Stores API key and saves the file.
func save_api_key(key: String) -> Error:
	if not _ensure_file(): return _load_error
	_file.set_value("api", "key", key)
	return save()

## Stores OAuth 2.0 client id and secret, and saves the file.
func save_client(id: String, secret := "") -> Error:
	if not _ensure_file(): return _load_error
	_file.set_value("client", "id", id)
	_file.set_value("client", "secret", secret)
	return save()

## Stores token keys and saves the file.
func save_oauth2_token_from_response(response: HTTPManagerResponse) -> Error:
	if not response.successful:
		push_error("Auth Token Request Error. Code: ", response.code)
		return FAILED
	
	var token_dict = response.parse()
	if not token_dict is Dictionary:
		push_error("Auth Token Response is not JSON: ", token_dict)
		return FAILED
	
	return save_oauth2_token_from_dict(token_dict)

## Stores token keys and saves the file.
func save_oauth2_token_from_dict(token_dict: Dictionary) -> Error:
	if not _ensure_file(): return _load_error
	
	if token_dict.has("error"):
		push_error("Error from Token Dict: ", token_dict)
		return FAILED
	
	if not token_dict.has("access_token"):
		push_error("No access token.")
		return FAILED
	
	for key in token_dict:
		var value = token_dict[key]
		if key == "expires_in":
			value = int(value)
			if value < 1000000000:
				value += int(Time.get_unix_time_from_system())
		_file.set_value("token", key, value)
	
	return save()

## Saves the file.
func save() -> Error:
	if not _ensure_file(): return _load_error
	
	var error := OK
	
	if _load_error == ERR_FILE_NOT_FOUND:
		if not DirAccess.dir_exists_absolute(_dir_path):
			error = DirAccess.make_dir_recursive_absolute(_dir_path)
			if error:
				push_error(error_string(error))
				return error
	
	error = _file.save(_file_path)
	if error:
		push_error(error_string(error))
	else:
		_load_error = OK
	return error

## Ensures [member _file] exists.
func _ensure_file() -> bool:
	if _file:
		return false if _load_error == ERR_FILE_BAD_PATH else true
	
	_file = ConfigFile.new()
	if subpath.is_empty():
		push_error("'subpath' is empty. It cannot save the file.")
		_load_error = ERR_FILE_BAD_PATH
		return false
	_dir_path = HTTPManagerClient.get_clients_dir().path_join(subpath)
	_file_path = _dir_path.path_join(HTTPManagerClient.CLIENT_FILENAME)
	_load_error = _file.load(_file_path)
	return true

#region Debug
## Prints file content.
func print_file() -> void:
	_ensure_file()
	for section in _file.get_sections():
		print("\n[" + section + "]")
		for key in _file.get_section_keys(section):
			print(key + " = " + str(_file.get_value(section, key)))
#endregion
