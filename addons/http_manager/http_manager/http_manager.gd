class_name HTTPManager extends Node

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

const Header := {
	ContentType = {
		URL_ENCODED = "Content-Type: application/x-www-form-urlencoded",
		JSON = "Content-Type: application/json",
	},
}

@export_range(1, 10) var max_active_requests := 1

## See [member HTTPRequest.download_chunk_size].
@export var download_chunk_size := 65536:
	set(value):
		download_chunk_size = value
		for http_request in _http_requests:
			http_request.download_chunk_size = value
## See [member HTTPRequest.use_threads].
@export var use_threads := false :
	set(value):
		use_threads = value
		for http_request in _http_requests:
			http_request.use_threads = value
## See [member HTTPRequest.accept_gzip].
@export var accept_gzip := true:
	set( value ):
		accept_gzip = value
		for http_request in _http_requests:
			http_request.accept_gzip = value
## See [member HTTPRequest.body_size_limit].
@export var body_size_limit:int = -1 :
	set( value ):
		body_size_limit = value
		for http_request in _http_requests:
			http_request.body_size_limit = value
## See [member HTTPRequest.max_redirects].
@export var max_redirects := 8:
	set(value):
		max_redirects = value
		for http_request in _http_requests:
			http_request.max_redirects = value
## See [member HTTPRequest.timeout].
@export var timeout: float = 0:
	set(value):
		timeout = value
		for http_request in _http_requests:
			http_request.timeout = value

@export_group("Cache", "cache_")
## Use cache.
@export var cache_enabled := false

var _active_requests := {}
var _mutex := Mutex.new()
var _http_requests: Array[HTTPRequest] = []
var _queue: Array[HTTPManagerRequestData] = []
var _rate_limited_domains := {}
var _active_http_requests: Array[HTTPRequest] = []


func _ready() -> void:
	resize_simultaneous_requests(max_active_requests)


## Añade un dominio con un límite de solicitudes por segundo. request_per_second debe ser mayor que cero.
func add_rate_limited_domain(url: String, request_per_second: int) -> Error:
	if _rate_limited_domains.has(url):
		_rate_limited_domains[url].wait_time = 1.0 / float(request_per_second)
		return ERR_ALREADY_EXISTS
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0 / float(request_per_second)
	timer.timeout.connect(_next)
	add_child(timer)
	_rate_limited_domains[url] = timer
	return OK


func cancel_all_requests() -> void:
	_mutex.lock()
	_queue.clear()
	for http_request in _active_requests.keys():
		http_request.cancel_request()
		_active_requests.erase(http_request)
	_mutex.unlock()


func cancel_request(request: HTTPManagerRequestData) -> void:
	_mutex.lock()
	var i := _queue.find(request)
	if i == -1:
		for http_request in _active_requests:
			if _active_requests[http_request] == request:
				if http_request is HTTPRequest:
					http_request.cancel_request()
				_active_requests.erase(http_request)
				_active_http_requests.append(http_request)
	else:
		_queue.remove_at(i)
	_mutex.unlock()


func cancel_requests(array: Array[HTTPManagerRequestData]) -> void:
	for r in array:
		cancel_request(r)


func get_simultaneous_request_count() -> int:
	return _active_http_requests.size() + _active_requests.size()


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


func request(url: String, custom_headers := PackedStringArray(), method: HTTPClient.Method = HTTPClient.METHOD_GET, request_data: String = "") -> HTTPManagerRequestData:
	for request in _queue:
		if request.url == url:
			return null
	for request in _active_requests.values():
		if request.url == url:
			return null
	var request := HTTPManagerRequestData.new()
	request.url = url
	request.headers = custom_headers
	request.method = method
	request.request_data = request_data
	_queue.append(request)
	_next.call_deferred()
	return request


func remove_rate_limited_domain(url: String) -> Error:
	var timer: Timer = _rate_limited_domains.get(url)
	if timer:
		timer.queue_free()
		_rate_limited_domains.erase(url)
		return OK
	return ERR_DOES_NOT_EXIST


func resize_simultaneous_requests(count: int) -> void:
	var n := get_simultaneous_request_count() - count
	if n == 0:
		return
	elif n > 0:
		for i in range(n):
			if not _active_http_requests.is_empty():
				_active_http_requests[0].queue_free()
				_active_http_requests.remove_at(0)
			elif not _active_requests.is_empty():
				var request: HTTPRequest = _active_requests.keys()[- 1]
				request.cancel_request()
				request.queue_free()
				_active_requests.erase(request)
	else:
		for i in range(-n):
			var request := HTTPRequest.new()
			request.request_completed.connect(_on_request_completed.bind(request))
			_active_http_requests.append(request)


func _can_request(url: String) -> bool:
	for key in _rate_limited_domains:
		if url.begins_with(key):
			var timer: Timer = _rate_limited_domains[key]
			if timer.is_stopped():
				timer.start()
				return true
			return false
	return true


func _next() -> void:
	_mutex.lock()
	if not _active_http_requests.is_empty():
		for i in range(_queue.size()):
			var request: HTTPManagerRequestData = _queue[i]
			if not _can_request(request.url):
				continue

			_queue.remove_at(i)

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
	_mutex.unlock()


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	_mutex.lock()
	var request: HTTPManagerRequestData = _active_requests[http_request]
	_active_requests.erase(http_request)
	remove_child(http_request)
	_active_http_requests.append(http_request)

	var response := HTTPManagerResponse.new()
	response.data = body
	response.headers = headers
	request.request_completed.emit(response)
	_mutex.unlock()
	_next()
