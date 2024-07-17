class_name HTTPManagerClient extends Resource


## API host or base url.
@export var host := ""
@export_range(0, 10, 1, "or_greater") var requests_per_second := 1.0
## Headers that are added when request starts with this client.
@export var headers := PackedStringArray()
## Priority.
@export var priority := 0

var http_client_count := 0
var countdowns := {}


var _queue: Array[HTTPManagerRequest] = []
var _pop_order := false:
	set(value):
		if _pop_order != value:
			_pop_order = value
			_queue.reverse()


func clear() -> void:
	_queue.clear()


func queue_request(r: HTTPManagerRequest) -> void:
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


func next_request() -> HTTPManagerRequest:
	if not _pop_order:
		_pop_order = true
	return _queue.pop_front()


func remove_request() -> bool:
	return false
