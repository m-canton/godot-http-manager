class_name HTTPManagerClient extends Resource


enum ArrayParamFormat {
	MULTIPLE, ## [code]foo=bar&foo=qux[/code]
	SQUARE_BRACKET_EMPTY, ## [code]foo[]=bar&foo[]=qux[/code]
	SQUARE_BRACKET_INDEX, ## [code]foo[0]=bar&foo[1]=qux[/code]
	COMMA_SEPARATED, ## [code]foo=bar,qux[/code]
}

## Host or base url.
@export var host := ""
## Port.
@export var port := -1
## Maximum concurrent requests.
@export_range(0, 10, 1, "or_greater") var max_concurrent_requests := 1
## Headers that are added when request starts with this client.
@export var headers: PackedStringArray = []
## Priority in HTTPManager to make requests.[br]
## [b]Note: [/b] It does nothing yet.
@export var priority := 0

@export_group("Constraint", "constraint_")
## Active constraint set index. See [member constraint_sets].
@export var constraint_current_set := 0
## Constraint sets. See [HTTPManagerConstraintSet].
@export var constraint_sets: Array[HTTPManagerConstraintSet] = []

@export_group("URL Params", "url_param_")
@export var url_param_bool_true := "1"
@export var url_param_bool_false := "0"
@export var url_param_array := ArrayParamFormat.MULTIPLE

## See [HTTPManager.next].
var http_client_count := 0

## Request queue.
var _queue: Array[HTTPManagerRequest] = []
## Queue order.
var _queue_asc := false:
	set(value):
		if _queue_asc != value:
			_queue_asc = value
			_queue.reverse()


func process(delta: float) -> void:
	for c in _current_constraints():
		if c.processing:
			if c.process(delta) and not _queue.is_empty():
				HTTPManager.next(self)


func clear() -> void:
	_queue.clear()


func queue(r: HTTPManagerRequest) -> void:
	if _queue_asc:
		_queue_asc = false
	
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
	
	HTTPManager.next(self)


func next() -> HTTPManagerRequest:
	if not _queue_asc:
		_queue_asc = true
	return _queue.pop_back()


func can_next() -> bool:
	if not _queue_asc:
		_queue_asc = true
	
	if _queue.is_empty():
		return false
	
	for c in _current_constraints():
		if not c.check(_queue[-1].route):
			return false
	return true


func is_empty() -> bool:
	return _queue.is_empty()


func _current_constraints() -> Array[HTTPManagerConstraint]:
	if constraint_current_set < 0 or constraint_current_set > constraint_sets.size():
		return []
	return constraint_sets[constraint_current_set].constraints
