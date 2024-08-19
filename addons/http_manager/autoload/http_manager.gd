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
## [HTTPClient] URL meta key.
const META_URL := &"url"
const META_REQUESTING := &"requesting"
const META_REDIRECTS := &"redirects"

## Active [HTTPManagerClient]. If a contraint is processing, client continues
## active.
var _clients: Array[HTTPManagerClient] = []
## Active [HTTPClient]s.
var _http_clients: Array[HTTPClient] = []


func _ready() -> void:
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
						hc.get_meta(META_URL).get_full_path(),
						r.headers,
						r.body)
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
	
	var i = r.route.client._queue.find(r)
	if i != -1:
		r.route.client._queue.remove_at(i)

## Cancels all the requests and clears queue from [param c] client. If [param c]
## is [code]null[/code], it cancels all the clients.
func cancel_all(c: HTTPManagerClient) -> void:
	for hc in _http_clients:
		if not c or hc.get_meta(META_REQUEST).route.client == c:
			_on_failure(hc)
	
	for c2 in _clients:
		if c2 == c:
			c.clear()
#endregion

#region Start Requests
## Starts a download.
## @experimental
func download(d: HTTPManagerDownload) -> Error:
	if not d:
		push_error("Download is null.")
		return FAILED
	
	push_error("Not implemented.")
	
	return OK

## Do not call this method. Use [method HTTPManagerRoute.create_request]
## instead.
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
	
	var uri := r.get_parsed_uri()
	if uri.is_empty():
		push_error("'uri' is empty. See the parse errors.")
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

## Do not call this method. This method is used by HTTPManager classes to make
## next request if constraints are released.
func _next(c: HTTPManagerClient) -> Error:
	if not c.can_next():
		return OK
	
	var r := c.next()
	if not r:
		return OK
	
	var hc := HTTPClient.new()
	if not _parse_url(hc, r.route.client.base_url + r.get_parsed_uri()):
		return ERR_PARSE_ERROR
	
	var parsed_url := hc.get_meta("url")
	var error := hc.connect_to_host(parsed_url.get_host(),
			parsed_url.port,
			r.tls_options)
	if error:
		push_error(error_string(error))
		return error
	
	hc.set_meta(META_REQUEST, r)
	hc.set_meta(META_RESPONSE, HTTPManagerResponse.new())
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
	var redirects: int = http_client.get_meta(META_REDIRECTS, 0)
	
	var response: HTTPManagerResponse = http_client.get_meta(META_RESPONSE)
	response.code = http_client.get_response_code() as HTTPClient.ResponseCode
	response.headers = http_client.get_response_headers()
	response.successful = true
	
	if response.code in [HTTPClient.RESPONSE_MOVED_PERMANENTLY, HTTPClient.RESPONSE_FOUND]:
		if redirects >= r.route.client.max_redirects:
			push_warning("Max redirects reached.")
			response.successful = false
			r.complete(response)
			return
		
		var location := ""
		for h in response.headers:
			if h.begins_with("Location:"):
				location = h.substr(9).strip_edges()
		
		if not location.is_empty() and _parse_url(http_client, location):
			http_client.set_meta(META_REDIRECTS, redirects + 1)
			http_client.close()
			http_client.set_meta(META_REQUESTING, false)
			var parsed_url: HTTPManagerClientParsedUrl = http_client.get_meta(META_URL)
			var error := http_client.connect_to_host(
					parsed_url.get_host(),
					parsed_url.port,
					r.tls_options)
			if not error:
				return
			
			response.successful = false
			push_error(error_string(error))
	
	_http_clients.erase(http_client)
	r.complete(response)
	_next(r.route.client)

## Parses the URL.
func _parse_url(http_client: HTTPClient, url: String) -> bool:
	var parsed_url := HTTPManagerClient.parse_url(url)
	if parsed_url == null:
		return false
	http_client.set_meta(META_URL, parsed_url)
	return true
