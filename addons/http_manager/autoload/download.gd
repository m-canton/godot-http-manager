class_name HTTPManagerDownload extends RefCounted

## HTTP Manager Download
## 
## This [RefCounted] is used to create a download with its URL.
## 
## @experimental

## Emitted when download is completed.
signal completed(response: HTTPManagerResponse)

const SETTING_NAME_MAX_CONCURRENT_DOWNLOADS := "addons/http_manager/max_concurrent_downloads"
const MAX_CONCURRENT_DOWNLOADS := 1

## Request URL.
var url := ""
## Headers.
var headers := PackedStringArray()
## Download path.
var path := ""
## Indicates if it stores the data in cache.
var cache := false
## It does nothing for now.
var priority := 0
## It indicates if it is valid.
var valid := true
## On complete listeners. See [HTTPManagerRequest.Listener].
var _listeners = {}
## Used to add Authorization header.
## @experimental
var _client_data: HTTPManagerClientData
## Used to add Authorization header.
## @experimental
var _auth_type: HTTPManagerRoute.AuthType

## Starts the download and set on complete listeners.
func start(listeners = null) -> Error:
	if not HTTPManagerRequest.http_manager:
		push_error("HTTPManager is not started.")
		return FAILED
	
	_listeners = HTTPManagerRequest.create_listeners_dict(listeners)
	return HTTPManagerRequest.http_manager.download(self)

## Completes this download.
func complete(response: HTTPManagerResponse) -> void:
	completed.emit(response)
	for key in _listeners:
		if key == HTTPManagerRequest.Listener.COMPLETE:
			_listeners[key].call(response)
		elif key == HTTPManagerRequest.Listener.SUCCESS:
			if response.successful:
				_listeners[key].call(response)
		elif key == HTTPManagerRequest.Listener.FAILURE:
			if not response.successful:
				_listeners[key].call(response)

#region Chain Methods
## Adds a header.
func add_header(h: String) -> HTTPManagerDownload:
	#var hkey := header.get_slice(":", 0) + ":" # To check if header exists.
	headers.append(h)
	return self

## Sets authorization. It does nothing for now.
## @experimental
func set_auth(client_data: HTTPManagerClientData, auth_type: HTTPManagerRoute.AuthType) -> HTTPManagerDownload:
	if auth_type in [HTTPManagerRoute.AuthType.OAUTH2_CHECK, HTTPManagerRoute.AuthType.API_KEY_CHECK]:
		_client_data = client_data
		_auth_type = auth_type
	return self
#endregion

## Creates a [HTTPManagerDownload] using an URL. Use [method start] to download
## the file.
static func create_from_url(new_url: String) -> HTTPManagerDownload:
	var d := HTTPManagerDownload.new()
	d.url = new_url
	return d

## Returns max concurrent downloads.
static func get_max_concurrent_downloads() -> int:
	return ProjectSettings.get_setting(SETTING_NAME_MAX_CONCURRENT_DOWNLOADS, MAX_CONCURRENT_DOWNLOADS)
