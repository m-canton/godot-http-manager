extends Node

## HTTPManager class
## 
## HTTPManager can do multiple concurrent requests with a limit.[br]
## [codeblock]
## @onready var http_manager := get_node("HTTPManager")
## 
## func make_a_request() -> void:
##     var request_data := http_manager.request("url")
##     if request_data:
##         request_data.request_completed(_on_a_request_completed)
## [/codeblock]

## [HTTPClient] request meta key.
const META_REQUEST := &"request"
## [HTTPClient] response meta key.
const META_RESPONSE := &"response"
## [HTTPClient] requestings meta key.
const META_REQUESTING := &"requesting"
## [HTTPClient] redirects meta key.
const META_REDIRECTS := &"redirects"

## Active [HTTPManagerClient]. If a contraint is processing, client continues
## active.
var _clients: Array[HTTPManagerClient]
## Active [HTTPClient]s.
var _http_clients: Array[HTTPClient]


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	set_process(false)
	HTTPManagerRequest.http_manager = self


func _process(delta: float) -> void:
	for hc in _http_clients:
		var error := hc.poll()
		var status := hc.get_status()
		if status == HTTPClient.STATUS_BODY:
			var r: HTTPManagerResponse = hc.get_meta(META_RESPONSE)
			var chunk := hc.read_response_body_chunk()
			if not chunk.is_empty():
				r.body.append_array(chunk)
		elif status == HTTPClient.STATUS_REQUESTING:
			hc.set_meta(META_REQUESTING, true)
		elif status == HTTPClient.STATUS_CONNECTING:
			pass
		elif status == HTTPClient.STATUS_RESOLVING:
			pass
		elif status == HTTPClient.STATUS_CONNECTED:
			if hc.get_meta(META_REQUESTING, false):
				_on_success(hc)
			else:
				var r: HTTPManagerRequest = hc.get_meta(META_REQUEST)
				error = hc.request(r.route.method as HTTPClient.Method,
						r.parsed_url.get_full_path(),
						r.headers,
						r.get_body_as_string())
				if error:
					_on_failure(hc)
		elif status == HTTPClient.STATUS_DISCONNECTED:
			_on_success(hc)
		elif status == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			push_error("tls handshake error...")
			_on_failure(hc)
		elif status == HTTPClient.STATUS_CONNECTION_ERROR:
			push_error("connection error")
			_on_failure(hc)
		elif status == HTTPClient.STATUS_CANT_CONNECT:
			push_error("cant connect")
			_on_failure(hc)
		elif status == HTTPClient.STATUS_CANT_RESOLVE:
			push_error("cant resolve")
			_on_failure(hc)
	
	for c in _clients:
		if c.process(delta):
			_next(c)

#region Cancel Requests
## Removes a request from queue or closes the [HTTPClient] that is requesting
## it.
func cancel(r: HTTPManagerRequest) -> void:
	for hc in _http_clients:
		if hc.get_meta(&"request") == r:
			_on_failure(hc)
			return
	
	r.route.client.cancel_request(r)

## Cancels all the requests and clears queue from [param c] client. If [param c]
## is [code]null[/code], it cancels all the clients.
func cancel_all(c: HTTPManagerClient) -> void:
	for hc in _http_clients:
		if not c or hc.get_meta(META_REQUEST).route.client == c:
			_on_failure(hc)
	
	for c2 in _clients:
		if c2 == c:
			c.cancel_requests()
#endregion

#region Start Requests
## Do not call this method. Use [method HTTPManagerRequest.start] instead.
## @experimental
func request(r: HTTPManagerRequest) -> Error:
	if not r:
		push_error("Request is null.")
		return FAILED
	
	if not r.valid:
		push_error("Request is not valid.")
		return FAILED
	
	var route := r.route
	if not route:
		push_error("Request has null route.")
		return FAILED
	
	var client := r.route.client
	if not client:
		push_error("Request route has null client.")
		return FAILED
	
	client.queue(r)
	_next(client)
	
	return OK

## Async request to use with await.
func fetch(r: HTTPManagerRequest) -> Variant:
	if request(r) == OK:
		var response: HTTPManagerResponse = await r.completed
		if response.successful:
			return response.parse()
		else:
			return null
	return null
#endregion

## Do not call this method. This method is used by HTTPManager to make next
## request if constraints are released.
func _next(c: HTTPManagerClient) -> Error:
	if not c.can_next():
		return OK
	
	var r := c.next()
	if not r:
		return OK
	
	var hc := HTTPClient.new()
	var error := hc.connect_to_host(r.parsed_url.get_host(),
			r.parsed_url.port, r.tls_options)
	if error:
		push_error(error_string(error))
		return error
	
	hc.set_meta(META_REQUEST, r)
	var response := HTTPManagerResponse.new()
	response.body = PackedByteArray()
	hc.set_meta(META_RESPONSE, response)
	_http_clients.append(hc)
	if not c in _clients:
		_clients.append(c)
	
	c.apply_constraints(r.route)
	
	set_process(true)
	
	return OK

## Called on request failure.
func _on_failure(http_client: HTTPClient) -> void:
	_http_clients.erase(http_client)
	
	var r: HTTPManagerResponse = http_client.get_meta(META_RESPONSE)
	r.headers = http_client.get_response_headers()
	r.code = http_client.get_response_code() as HTTPClient.ResponseCode
	push_error("Request error with code: ", r.code)
	http_client.get_meta(META_REQUEST).complete(r)

## Called on request success.
func _on_success(http_client: HTTPClient) -> void:
	var r: HTTPManagerRequest = http_client.get_meta(META_REQUEST)
	
	var response: HTTPManagerResponse = http_client.get_meta(META_RESPONSE)
	response.code = http_client.get_response_code() as HTTPClient.ResponseCode
	response.headers = http_client.get_response_headers()
	response.successful = true
	
	if response.code in [HTTPClient.RESPONSE_MOVED_PERMANENTLY, HTTPClient.RESPONSE_FOUND]:
		var redirects: int = http_client.get_meta(META_REDIRECTS, 0)
		if redirects >= r.route.client.max_redirects:
			push_warning("Max redirects reached.")
			response.successful = false
			r.complete(response)
			return
		
		var location := ""
		for h in response.headers:
			if h.begins_with("Location:"):
				location = h.substr(9).strip_edges()
		
		r.parsed_url = HTTPManagerClient.parse_url(location)
		if not location.is_empty() and r.parsed_url:
			http_client.set_meta(META_REDIRECTS, redirects + 1)
			http_client.close()
			http_client.set_meta(META_REQUESTING, false)
			var error := http_client.connect_to_host(
					r.parsed_url.get_host(),
					r.parsed_url.port,
					r.tls_options)
			if not error:
				return
			
			response.successful = false
			push_error(error_string(error))
	
	_http_clients.erase(http_client)
	r.complete(response)
	_next(r.route.client)

#region Downloads
## Downloads file to reference cache.
const DOWNLOADS_FILE_PATH := "user://addons/http_manager/downloads.ini"

var _downloads_file: ConfigFile
## [HTTPManagerDownload] queue.
var _downloads: Array[HTTPManagerDownload]
## [HTTPRequest]s to download files.
var _active_downloads := 0
## Max concurrent downloads from project settings.
var _max_concurrent_downloads := HTTPManagerDownload.get_max_concurrent_downloads()

## Starts a download.
## @experimental
func download(d: HTTPManagerDownload) -> Error:
	if not HTTPManagerDownload:
		push_error("Download is null.")
		return FAILED
	
	if not d.valid:
		push_error("Invalid download: ", d.url)
		return FAILED
	
	_downloads.append(d)
	_next_download()
	return OK

func _ensure_downloads_file() -> Error:
	return FAILED

func _next_download(hr: HTTPRequest = null) -> void:
	if _active_downloads >= _max_concurrent_downloads:
		return
	
	var d: HTTPManagerDownload = _downloads.pop_front()
	if not d:
		if hr: hr.queue_free()
		return
	
	if not hr:
		hr = HTTPRequest.new()
		hr.request_completed.connect(_on_download_completed.bind(hr.get_instance_id()))
		add_child(hr)
	
	var error := hr.request(d.url)
	if error:
		var response := HTTPManagerResponse.new()
		response.body = "Request Error: " + error_string(error)
		response.headers.append(MIME.type_to_content_type(MIME.Type.TEXT))
		response.successful = false
		d.complete(response)
		_next_download(hr)
	else:
		hr.set_meta(&"download", d)
		_active_downloads += 1

## Called on download completed.
func _on_download_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, hrid: int) -> void:
	var response := HTTPManagerResponse.new()
	response.successful = true
	response.code = response_code
	response.headers = headers
	response.body = body
	
	var hr: HTTPRequest = instance_from_id(hrid)
	var d: HTTPManagerDownload = hr.get_meta(&"download")
	d.complete(response)
	
	_active_downloads -= 1
	_next_download(hr)
#endregion
