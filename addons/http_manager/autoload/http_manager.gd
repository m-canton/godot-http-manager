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
const HTTP_CLIENT_META_REQUEST := &"request"
## [HTTPClient] response meta key.
const HTTP_CLIENT_META_RESPONSE := &"response"

## Active [HTTPManagerClient]. If a contraint is processing, client continues
## active.
var _clients: Array[HTTPManagerClient] = []
## Active [HTTPClient]s.
var _http_clients: Array[HTTPClient] = []


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	for hc in _http_clients:
		var error := hc.poll()
		var status := hc.get_status()
		if status == HTTPClient.STATUS_BODY:
			var r: HTTPManagerResponse = hc.get_meta(HTTP_CLIENT_META_RESPONSE)
			var chunk := hc.read_response_body_chunk()
			if not chunk.is_empty():
				r.body.append_array(chunk)
		elif status == HTTPClient.STATUS_REQUESTING:
			hc.set_meta("requesting", true)
		elif status == HTTPClient.STATUS_CONNECTING:
			pass
		elif status == HTTPClient.STATUS_RESOLVING:
			pass
		elif status == HTTPClient.STATUS_CONNECTED:
			if hc.get_meta("requesting", false):
				_on_success(hc)
			else:
				var r: HTTPManagerRequest = hc.get_meta(HTTP_CLIENT_META_REQUEST)
				error = hc.request(r.route.method as HTTPClient.Method, r.get_parsed_uri(), r.headers, r.body)
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
		if hc.get_meta("request") == r:
			_on_failure(hc)
			return
	
	var i = r.route.client._queue.find(r)
	if i != -1:
		r.route.client._queue.remove_at(i)

## Cancels all the requests and clears queue from [param c] client. If [param c]
## is [code]null[/code], it cancels all the clients.
func cancel_all(c: HTTPManagerClient) -> void:
	for hc in _http_clients:
		if not c or hc.get_meta(HTTP_CLIENT_META_REQUEST).route.client == c:
			_on_failure(hc)
	
	for c2 in _clients:
		if c2 == c:
			c.clear()
#endregion

## Do not call this method. Use [method HTTPManager.create_request_from_route]
## instead.
## @experimental
func request(r: HTTPManagerRequest) -> Error:
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

func fetch(r: HTTPManagerRequest) -> Variant:
	if request(r) == OK:
		var response: HTTPManagerResponse = await r.completed
		if response.successful:
			return response.parse()
		else:
			return null
	return null

## Do not call this method. This method is used by HTTPManager classes to make
## next request if constraints are released.
func _next(c: HTTPManagerClient) -> Error:
	if not c.can_next():
		return OK
	
	var r := c.next()
	if not r:
		return OK
	
	var hc := HTTPClient.new()
	var error := hc.connect_to_host(r.route.client.host, r.route.client.port, r.tls_options)
	if error:
		push_error(error_string(error))
		return error
	
	hc.set_meta(HTTP_CLIENT_META_REQUEST, r)
	hc.set_meta(HTTP_CLIENT_META_RESPONSE, HTTPManagerResponse.new())
	_http_clients.append(hc)
	if not c in _clients:
		_clients.append(c)
	
	c.apply_constraints(r.route)
	
	set_process(true)
	
	return OK

## Adds TLS Options to a client. For now it is not used.
## @experimental
func set_tls_options(client: HTTPManagerClient, tls_options: TLSOptions) -> Error:
	if not client:
		push_error("Client is null.")
		return FAILED
	
	client.tls_options = tls_options
	return OK


func _on_failure(http_client: HTTPClient) -> void:
	_http_clients.erase(http_client)
	
	var r: HTTPManagerResponse = http_client.get_meta(HTTP_CLIENT_META_RESPONSE)
	r.code = http_client.get_response_code() as HTTPClient.ResponseCode
	push_error("Request error with code:", r.code)
	http_client.get_meta(HTTP_CLIENT_META_REQUEST).complete(r)


func _on_success(http_client: HTTPClient) -> void:
	_http_clients.erase(http_client)
	
	var r: HTTPManagerRequest = http_client.get_meta(HTTP_CLIENT_META_REQUEST)
	var response: HTTPManagerResponse = http_client.get_meta(HTTP_CLIENT_META_RESPONSE)
	response.code = http_client.get_response_code() as HTTPClient.ResponseCode
	response.headers = http_client.get_response_headers_as_dictionary()
	response.successful = true
	r.complete(response)
	
	_next(r.route.client)
