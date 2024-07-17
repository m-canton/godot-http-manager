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


var _clients: Array[HTTPManagerClient] = []
var _http_clients: Array[HTTPClient] = []

var _active_http_requests: Array[HTTPRequest] = []


func _process(delta: float) -> void:
	for c in _clients:
		c.clients
		
		for key in c.countdowns:
			c[key] -= delta
			if c[key] <= 0.0:
				c.countdowns.erase(key)
				_next(c)

## Cancels all the requests and clears queue from [param c] client. If [param c]
## is [code]null[/code], it cancels all the clients.
func cancel_all(c: HTTPManagerClient) -> void:
	for hc in _http_clients:
		if not c or hc.get_meta("request").route.client == c:
			hc.close()
	
	for c2 in _clients:
		if c2 == c:
			c.clear()

## Removes a request from queue or closes the [HTTPClient] that is requesting
## it.
func cancel(r: HTTPManagerRequest, close_connection := false) -> void:
	for hc in _http_clients:
		if hc.get_meta("request") == r:
			hc.close()
			return
	
	var i = r.route.client._queue.find(r)
	if i != -1:
		r.route.client._queue.remove_at(i)


func query_string_from_dict(dict: Dictionary) -> String:
	var query := "";
	for key in dict:
		var encoded_key = key.uri_encode()
		var value = dict[key]
		match typeof(value):
			TYPE_ARRAY:
				# Repeat the key with every values
				var values: Array = value
				for v in values:
					query += "&" + encoded_key + "=" + v.uri_encode();
			TYPE_NIL:
				# Add the key with no value
				query += "&" + encoded_key;
			_:
				# Add the key-value pair
				query += "&" + encoded_key + "=" + str(value).uri_encode();
	return query.substr(1);


func request(r: HTTPManagerRequest) -> void:
	var route := r.route
	if not route:
		push_error("Request has null route.")
		return
	
	var client := r.route.client
	if not client:
		push_error("Request route has null client.")
		return
	
	client.queue_request(r)


func _can_request(url: String) -> bool:
	for key in _rate_limited_domains:
		if url.begins_with(key):
			var timer: Timer = _rate_limited_domains[key]
			if timer.is_stopped():
				timer.start()
				return true
			return false
	return true


func _next(c: HTTPManagerClient) -> void:
	if not _active_http_requests.is_empty():
		for i in range(_queue.size()):
			var request: HTTPManagerRequest = _queue[i]
			if not _can_request(request.url):
				continue

			var http_request: HTTPRequest = _active_http_requests.pop_back()
			add_child(http_request)
			_active_requests[http_request] = request
			if http_request.request(request.url, request.headers, request.method, request.request_data) == OK:
				break

			_active_requests.erase(http_request)
			remove_child(http_request)
			_active_http_requests.append(http_request)

			var response := HTTPManagerResponse.new()
			response.error_message = "Request Error"
			request.request_completed.emit(response)


func _on_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var r: HTTPManagerRequest = _active_requests[http_request]
	_active_requests.erase(http_request)
	remove_child(http_request)
	_active_http_requests.append(http_request)

	var response := HTTPManagerResponse.new()
	response.data = body
	response.headers = headers
	r.completed.emit(response)
	_next(r.route.client)
