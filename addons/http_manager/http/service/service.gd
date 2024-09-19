class_name HTTPManagerService extends RefCounted

## Define a API wrapper extending this class. Create methods which return
## requests to start anywhere.[br]
## To split routes, you can extend [HTTPManagerServiceGroup] class. After you
## define a method that returns this class and set your service. You can use
## [code]class_name[/code] to get autocompletion in your scripts.

## Setting name for client data dir to save data.
const SETTING_NAME_DIR := "addons/http_manager/services/data_dir"
## Default setting value for clients dir.
const DEFAULT_DIR := "user://addons/http_manager"

const SERVICE_FILENAME := "service.ini"
var _config_file: ConfigFile
var _current_request: HTTPManagerRequest

#region Overrideable Methods
## Base URL.[br]
## You can override this method to set a prefix in your API branches:
## [codeblock]
## #api_posts.gd
## [/codeblock]
func _base_url() -> String:
	return ""

## Returns service name. Recommended to use snake case and subdirectories
## separated by dots.
func _service_name() -> String:
	return ""


func _default_auth() -> Array[HTTPManagerAuth]:
	return []


func _default_oauth_config() -> HTTPManagerOAuthConfig:
	return null
#endregion

## Loads a branch using relative path and sets a prefix for endpoints.
func load_branch(path: String, prefix: String) -> HTTPManagerServiceBranch:
	if not path.ends_with(".gd"):
		path += ".gd"
	
	var group := load(get_path(path)) as Script
	return group.new(self, prefix) if group else null

func get_url(path: String) -> String:
	return _base_url().path_join(path)

func get_path(path: String) -> String:
	return (get_script() as Script).resource_path.get_base_dir().path_join(path)

## Returns service file.
func get_data_file() -> ConfigFile:
	if not _config_file:
		_config_file = ConfigFile.new()
		_config_file.load(get_data_dir().path_join(SERVICE_FILENAME))
	return _config_file

## Returns service dir.
func get_data_dir() -> String:
	return HTTPManagerService.get_user_dir().path_join(_service_name())

## Sets authentication credentials in the current request. It uses authenticator from
## [method _default_auth] if [param authenticators] is empty.
func authorize(auths: Array[HTTPManagerAuth] = []) -> Error:
	if auths.is_empty():
		auths = _default_auth()
	
	for a in auths:
		var r := a.handle(_current_request)
		if r:
			r.start()
	
	return OK


## Returns services dir from project settings.
static func get_user_dir() -> String:
	return ProjectSettings.get_setting(SETTING_NAME_DIR, DEFAULT_DIR)
