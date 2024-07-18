class_name HTTPManagerClient extends Resource


## Host or base url.
@export var host := ""
## Port.
@export var port := -1
## Requests per second.
@export_range(0, 10, 1, "or_greater") var requests_per_second := 1.0
## Maximum concurrent requests.
@export_range(0, 10, 1, "or_greater") var max_concurrent_requests := 1
## Headers that are added when request starts with this client.
@export var headers := PackedStringArray()
## Priority in HTTPManager to make requests.[br]
## [b]Note: [/b] It does nothing yet.
@export var priority := 0

## See [HTTPManager._next].
var http_client_count := 0
## See [HTTPManagerClient.request_per_second].
var countdowns := {}

##
var _queue: Array[HTTPManagerRequest] = []
var _pop_order := false:
	set(value):
		if _pop_order != value:
			_pop_order = value
			_queue.reverse()


func clear() -> void:
	_queue.clear()


func queue(r: HTTPManagerRequest) -> void:
	if _pop_order:
		_pop_order = false
	
	if r.priority < 0:
		r.priority = r.route.priority
	
	var i := 0
	var qsize := _queue.size()
	while i < qsize:
		if r.priority < _queue[i].priority:
			_queue.insert(i, r)
			break
		i += 1
	
	if i == qsize:
		_queue.append(r)


func next() -> HTTPManagerRequest:
	if not _pop_order:
		_pop_order = true
	return _queue.pop_front()


func can_next() -> bool:
	return http_client_count < max_concurrent_requests and countdowns.is_empty()


func is_empty() -> bool:
	return _queue.is_empty()
