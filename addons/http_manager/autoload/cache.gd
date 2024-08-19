class_name HTTPManagerCache extends Node

## @experimental

const _CACHE_FILE_PATH := "user://addons/http_manager/cache.ini"
static var _cache_file := ConfigFile.new()


static func _static_init() -> void:
	_cache_file.load(_CACHE_FILE_PATH)


static func save_cache() -> void:
	_cache_file.save(_CACHE_FILE_PATH)


func set_value(key, value, duration := 3600) -> void:
	pass
