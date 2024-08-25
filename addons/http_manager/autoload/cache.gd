class_name HTTPManagerCache extends Node

## HTTP Manager Cache.
## 
## It handles cache files.
## 
## @experimental

const SETTING_NAME_FILE_PATH := "addons/http_manager/cache/file"
const SETTING_NAME_DIR_PATH := "addons/http_manager/cache/dir"
const SETTING_NAME_MAX_SIZE := "addons/http_manager/cache/max_size"
const SETTING_NAME_MAX_FILE_SIZE := "addons/http_manager/cache/max_file_size"

## [member _dir_path] default value. Change it in project settings.
const DEFAULT_DIR_PATH := "user://addons/http_manager/.cache"
## [member _file_path] default value. Change it in project settings.
const DEFAULT_FILE_PATH := "user://addons/http_manager/cache.ini"
## [member _max_file_size] default value. Change it in project settings.
const DEFAULT_MAX_FILE_SIZE := 5
## [member _max_size] default value. Change it in project settings.
const DEFAULT_MAX_SIZE := 200

## Cache counter to return unique IDs with [method _get_unique_id].
var _counter := 0
## File data to search files in cache.
var _files: Array[Dictionary] = []
## Cache file.
var _file: ConfigFile
## Cache file path.
var _file_path: String = ProjectSettings.get_setting(SETTING_NAME_FILE_PATH, DEFAULT_FILE_PATH)
## Cache file error.
var _file_error := OK
## Cache dir path to store cache files.
var _dir_path: String = ProjectSettings.get_setting(SETTING_NAME_DIR_PATH, DEFAULT_DIR_PATH)
var _dir_check := false
var _dir_error := OK
## Cache max individual file size to store in MB. It cannot save larger files.
var _max_file_size: int = ProjectSettings.get_setting(SETTING_NAME_MAX_FILE_SIZE, DEFAULT_MAX_FILE_SIZE) * 1024 * 1024
## Cache max size to store in MB.
var _max_size: int = ProjectSettings.get_setting(SETTING_NAME_MAX_SIZE, DEFAULT_MAX_SIZE) * 1024 * 1024
## Current cache size in Bytes.
var _current_size := 0

## Removes all the files in cache dir and clears [member _files].
func clear_files(_megabytes := -1) -> void:
	_ensure_file()
	var dir := DirAccess.open(_dir_path)
	if dir and dir.list_dir_begin() == OK:
		var filename := dir.get_next()
		while filename != "":
			dir.remove(filename)
			filename = dir.get_next()
	_files.clear()
	_current_size = 0
	_save()

## Returns an unique ID to reference files. Make sure to save the cache file
## after calling it.
func _get_unique_id() -> int:
	_ensure_file()
	_counter += 1
	return _counter

## Ensures cache dir exists.
func _ensure_dir() -> Error:
	if not _dir_check:
		if not DirAccess.dir_exists_absolute(_dir_path):
			_dir_error = DirAccess.make_dir_recursive_absolute(_dir_path)
		_dir_check = true
	return _dir_error

## Ensures cache file exists.
func _ensure_file() -> Error:
	if not _file:
		_file = ConfigFile.new()
		_file_error = _file.load(DEFAULT_FILE_PATH)
		if _file_error == OK:
			_counter = _file.get_value("cache", "counter", 0)
			_current_size = _file.get_value("cache", "size", 0)
			_files = _file.get_value("cache", "files", [])
		else:
			# Ensures file dir
			var bdir := _file_path.get_base_dir()
			if not DirAccess.dir_exists_absolute(bdir):
				var error := DirAccess.make_dir_recursive_absolute(bdir)
				if error:
					push_error(error_string(error))
					_file_error = error
					return error
	return _file_error

## Saves cache file.
func _save() -> Error:
	_ensure_file()
	_file.set_value("cache", "counter", _counter)
	_file.set_value("cache", "files", _files)
	_file.set_value("cache", "size", _current_size)
	return _file.save(_file_path)

## Returns file [Dictionary].
func _get_file_dict(uri: String) -> Dictionary:
	_ensure_file()
	var i := 0
	var count := _files.size()
	while i < count:
		var d := _files[i]
		if d.uri == uri:
			d.timestamp = int(Time.get_unix_time_from_system())
			_files.remove_at(i)
			_files.push_front(d)
			_save()
			return d
		i += 1
	return {}

## Returns cached file path.
func _get_file_path(id: int) -> String:
	_ensure_file()
	return _dir_path.path_join(str(id))

## Returns file content in cache as [PackedByteArray].
func get_file_buffer(uri: String) -> PackedByteArray:
	var d := _get_file_dict(uri)
	if d.is_empty(): return []
	var b := FileAccess.get_file_as_bytes(_get_file_path(d.id))
	if FileAccess.get_open_error():
		var i := _files.find(d)
		if i != -1: _files.remove_at(i)
	return b

func get_file_response(uri: String) -> HTTPManagerResponse:
	var d := _get_file_dict(uri)
	if d.is_empty(): return null
	var b := FileAccess.get_file_as_bytes(_get_file_path(d.id))
	if FileAccess.get_open_error():
		var i := _files.find(d)
		if i != -1: _files.remove_at(i)
		return null
	
	var response := HTTPManagerResponse.new()
	response.body = b
	response.code = HTTPClient.RESPONSE_OK
	response.headers.append(MIME.type_to_content_type(d.type, d.attributes))
	response.successful = true
	return response

## Returns file content in cache as [String].
func get_file_string(uri: String) -> String:
	var d := _get_file_dict(uri)
	if d.is_empty(): return ""
	var s := FileAccess.get_file_as_string(_get_file_path(d.id))
	if FileAccess.get_open_error():
		var i := _files.find(d)
		if i != -1: _files.remove_at(i)
	return s

## Stores a file using [HTTPManagerResponse].
func store_file_from_response(response: HTTPManagerResponse, uri: String) -> Error:
	var content: PackedByteArray
	if response.body is String:
		content = response.body.to_utf8_buffer()
	elif response.body is PackedByteArray:
		content = response.body
	else:
		push_error("Invalid Response Body.")
		return FAILED
	
	var ct := response.get_content_type()
	var options := {}
	if ct != "":
		options["type"] = MIME.string_to_type(ct)
		options["attributes"] = MIME.get_attributes(ct)
	return store_file(content, uri, options)

## Stores a file in cache. Options: type, attributes and ttl. [br]
## [b]Note:[/b] It cannot store empty content.
func store_file(content: PackedByteArray, uri: String, options := {}) -> Error:
	if uri == "":
		push_error("URI is empty.")
		return FAILED
	
	if content.is_empty():
		push_error("Content is empty.")
		return FAILED
	
	if not _ensure_file() in [OK, ERR_FILE_NOT_FOUND]:
		push_error("It cannot ensure cache file.")
		return _file_error
	
	if _ensure_dir():
		push_error("It cannot ensure cache dir.")
		return _dir_error
	
	# Check content size
	var content_size := content.size()
	if content_size > _max_file_size:
		push_error("Content is too large: ", content_size, " > ", _max_file_size)
		return ERR_OUT_OF_MEMORY
	
	# Create file dict
	var id := _get_unique_id()
	var dict := {
		uri = uri,
		id = id,
		type = options.get("type", MIME.Type.NONE),
		attributes = options.get("attributes", {}),
		size = content_size,
		timestamp = int(Time.get_unix_time_from_system())
	}
	
	# Check time to live
	if options.has("ttl") and options.ttl is int:
		var t := Time.get_unix_time_from_system()
		if options.ttl < t:
			options.ttl += t
		dict["ttl"] = options.ttl
	
	# Check cache size
	var error := OK
	_current_size += content_size
	while not _files.is_empty() and _current_size > _max_size:
		var d: Dictionary = _files.pop_back()
		error = DirAccess.remove_absolute(_get_file_path(d.id))
		if error:
			push_error(error_string(error))
		_current_size -= d.size
	
	_files.push_front(dict)
	
	error = _save()
	if error:
		push_error(error_string(error))
		return error
	
	var file := FileAccess.open(_get_file_path(id), FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_buffer(content)
	
	return OK

## It does nothing for now. It stores key-value with expire time.
## @experimental
func set_value(_key, _value, _duration := 3600) -> void:
	pass
