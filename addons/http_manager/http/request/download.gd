class_name HTTPManagerDownload extends HTTPManagerStream

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
## Download path.
var path := ""
## Indicates if response body is set when download path is specified.
var response_body := true
## It stores data in cache if it is non-negative.
var cache_delay := -1.0
## It does nothing for now.
var priority := 0
## It indicates if it is valid.
var valid := true
## Content encoding.
var content_encoding := PackedStringArray()
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
	return HTTPManagerRequest.http_manager.start_download(self)

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
## See [method HTTPManagerStream].
func set_header(new_header: String) -> HTTPManagerDownload:
	return super(new_header)

## Requests content encoding gzip.
func set_gzip() -> HTTPManagerDownload:
	if not content_encoding.has("gzip"):
		content_encoding.append("gzip")
	return self

## Requests content encoding deflate.
## @experimental
func set_deflate() -> HTTPManagerDownload:
	if not content_encoding.has("deflate"):
		content_encoding.append("deflate")
	return self

## Sets authorization. It does nothing for now.
## @experimental
func set_auth(client_data: HTTPManagerClientData, auth_type: HTTPManagerRoute.AuthType) -> HTTPManagerDownload:
	if auth_type in [HTTPManagerRoute.AuthType.TOKEN_CHECK, HTTPManagerRoute.AuthType.API_KEY_CHECK]:
		_client_data = client_data
		_auth_type = auth_type
	return self

## Enables cache.
func set_cache(delay := 0.0) -> HTTPManagerDownload:
	cache_delay = delay
	return self

## Sets path. If you do not need file content in response body, set
## [code]false[/false] in [param set_response_body].
func set_path(new_path: String, set_response_body := true) -> HTTPManagerDownload:
	path = new_path
	response_body = set_response_body
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

## Scales down an image to fit the specified size.
static func image_scale_down(image: Image, max_length: int) -> void:
	var isize := image.get_size()
	if isize.x > isize.y:
		if isize.x > max_length:
			image.resize(max_length, int(max_length / isize.aspect()))
	elif isize.y > max_length:
		image.resize(int(max_length * isize.aspect()), max_length)
