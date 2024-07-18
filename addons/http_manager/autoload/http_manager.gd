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

enum HTTPClientMeta {
	REQUEST,
	RESPONSE,
}

const HTTP_CLIENT_META_REQUEST := &"request"
const HTTP_CLIENT_META_RESPONSE := &"response"

var _clients: Array[HTTPManagerClient] = []
var _http_clients: Array[HTTPClient] = []


func _process(delta: float) -> void:
	for hc in _http_clients:
		var _error := hc.poll()
		var status := hc.get_status()
		if status == HTTPClient.STATUS_BODY:
			print("body")
			var r: HTTPManagerResponse = hc.get_meta(HTTP_CLIENT_META_RESPONSE)
			var chunk := hc.read_response_body_chunk()
			if not chunk.is_empty():
				r.body.append_array(chunk)
		elif status == HTTPClient.STATUS_REQUESTING:
			hc.set_meta("requesting", true)
			print("requesting...")
		elif status == HTTPClient.STATUS_CONNECTING:
			print("connecting...")
		elif status == HTTPClient.STATUS_CONNECTED:
			if hc.get_meta("requesting", false):
				_on_success(hc)
			else:
				var r: HTTPManagerRequest = hc.get_meta(HTTP_CLIENT_META_REQUEST)
				hc.request(r.route.method as HTTPClient.Method, r.route.endpoint, r.headers, r.body)
		elif status == HTTPClient.STATUS_RESOLVING:
			print("resolving...")
			pass
		elif status == HTTPClient.STATUS_DISCONNECTED:
			print("disconnected")
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
		for key in c.countdowns:
			c[key] -= delta
			if c[key] <= 0.0:
				c.countdowns.erase(key)
				_next(c)

## Cancels all the requests and clears queue from [param c] client. If [param c]
## is [code]null[/code], it cancels all the clients.
func cancel_all(c: HTTPManagerClient) -> void:
	for hc in _http_clients:
		if not c or hc.get_meta(HTTP_CLIENT_META_REQUEST).route.client == c:
			hc.close()
	
	for c2 in _clients:
		if c2 == c:
			c.clear()

## Removes a request from queue or closes the [HTTPClient] that is requesting
## it.
func cancel(r: HTTPManagerRequest) -> void:
	for hc in _http_clients:
		if hc.get_meta("request") == r:
			hc.close()
			return
	
	var i = r.route.client._queue.find(r)
	if i != -1:
		r.route.client._queue.remove_at(i)


func request(r: HTTPManagerRequest) -> void:
	var route := r.route
	if not route:
		push_error("Request has null route.")
		return
	
	var client := r.route.client
	if not client:
		push_error("Request route has null client.")
		return
	
	client.queue(r)
	_next(r.route.client)


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
	r.complete(response)
	
	_next(r.route.client)