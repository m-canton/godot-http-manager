@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("HTTPManager", "res://addons/http_manager/autoload/http_manager.gd")
	
	# Settings
	_set_setting(HTTPManagerDownload.SETTING_NAME_MAX_CONCURRENT_DOWNLOADS, HTTPManagerDownload.MAX_CONCURRENT_DOWNLOADS)
	_set_setting(HTTPManagerClient.SETTING_NAME_DIR, HTTPManagerClient.DEFAULT_DIR)
	_set_setting(HTTPManagerCache.SETTING_NAME_FILE_PATH, HTTPManagerCache.DEFAULT_FILE_PATH)
	_set_setting(HTTPManagerCache.SETTING_NAME_DIR_PATH, HTTPManagerCache.DEFAULT_DIR_PATH)
	_set_setting(HTTPManagerCache.SETTING_NAME_MAX_SIZE, HTTPManagerCache.DEFAULT_MAX_SIZE)
	_set_setting(HTTPManagerCache.SETTING_NAME_MAX_FILE_SIZE, HTTPManagerCache.DEFAULT_MAX_FILE_SIZE)
	_set_setting(OAuth2.SETTING_NAME_BIND_ADDRESS, OAuth2.DEFAULT_BIND_ADDRESS)
	_set_setting(OAuth2.SETTING_NAME_PORT, OAuth2.DEFAULT_PORT)
	_set_setting(OAuth2.SETTING_NAME_CALLBACK_PATH, OAuth2.DEFAULT_CALLBACK_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton("HTTPManager")


func _set_setting(setting_name: String, default_value, basic := true, property_info := {}) -> void:
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, default_value)
	ProjectSettings.set_initial_value(setting_name, default_value)
	ProjectSettings.set_as_basic(setting_name, basic)
	if not property_info.is_empty():
		property_info["name"] = setting_name
		property_info["type"] = property_info.get("type", typeof(default_value))
		ProjectSettings.add_property_info(property_info)
