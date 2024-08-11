@tool
class_name HTTPManagerClient extends Resource

## HTTPManager Client resource.
## 
## This resource defines a client to use it in [HTTPManagerRoute] resources.

enum ArrayParamFormat {
	MULTIPLE, ## [code]foo=bar&foo=qux[/code]
	SQUARE_BRACKET_EMPTY, ## [code]foo[]=bar&foo[]=qux[/code]
	SQUARE_BRACKET_INDEX, ## [code]foo[0]=bar&foo[1]=qux[/code]
	ENCODED_SQUARE_BRACKET_EMPTY, ## [code]foo[]=bar&foo[]=qux[/code]
	ENCODED_SQUARE_BRACKET_INDEX, ## [code]foo[0]=bar&foo[1]=qux[/code]
	COMMA_SEPARATED, ## [code]foo=bar,qux[/code]
	SPACE_SEPARATED, ## [code]foo=bar aux[/code]
}

enum BaseUrlInput {
	FULL,
	SPLIT,
}

@export var base_url_input := BaseUrlInput.FULL:
	set(value):
		if base_url_input != value:
			base_url_input = value
			if base_url_input == BaseUrlInput.FULL:
				var s := host
				if port != -1:
					s += str(":", port)
				if not prefix.is_empty():
					s += prefix
				base_url = s
			notify_property_list_changed()
## Host or base url.
@export var base_url := "":
	set(value):
		if base_url != value:
			base_url = value
			_parse_base_url()
@export var host := "":
	set(value):
		if host != value:
			host = value
## Port.
@export var port := -1:
	set(value):
		if port != value:
			port = value
## Route prefix. In API with base url "https://example.com/v2", prefix is "/v2".
@export var prefix := "":
	set(value):
		if prefix != value:
			prefix = value

## Headers that are added when request starts with this client.
@export var headers: PackedStringArray = []
## Priority in HTTPManager to make requests.[br]
## [b]Note: [/b] It does nothing yet.
## @experimental
@export var priority := 0
## Maximum concurrent requests.
@export_range(0, 10, 1, "or_greater") var max_concurrent_requests := 1
## Maximum concurrent requests.
@export_range(0, 10, 1, "or_greater") var max_concurrent_downloads := 1

@export_group("Constraint", "constraint_")
## Active constraint set index. See [member constraint_sets].
@export var constraint_current_set := 0
## Constraint sets. See [HTTPManagerConstraintSet].
@export var constraint_sets: Array[HTTPManagerConstraintSet] = []

@export_group("URL Params", "url_param_")
## Replaces [code]true[/code] value by this string in url param values.
@export var url_param_bool_true := "1"
## Replaces [code]false[/code] value by this string in url param values.
@export var url_param_bool_false := "0"
## Array format for url param values. See [enum ArrayParamFormat].
@export var url_param_array_format := ArrayParamFormat.MULTIPLE

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
var tls_options: TLSOptions


func process(delta: float) -> bool:
	for c in _current_constraints():
		if c.processing:
			return c.process(delta) and not _queue.is_empty()
	return false


func _validate_property(property: Dictionary) -> void:
	if property.name == "base_url":
		if base_url_input == BaseUrlInput.SPLIT:
			property.usage ^= PROPERTY_USAGE_EDITOR
	elif property.name in ["host", "port", "prefix"]:
		if base_url_input == BaseUrlInput.FULL:
			property.usage ^= PROPERTY_USAGE_EDITOR


func _parse_base_url() -> void:
	var protocol := ""
	var s := base_url.split("://", false, 1)
	var ss := s.size()
	if ss > 1:
		protocol = s[0] + "://"
		s[0] = s[1]
	
	if ss == 0:
		host = protocol + ""
		port = -1
		prefix = ""
	else:
		s = s[0].split("/", false, 1)
		ss = s.size()
		if ss == 0:
			host = protocol + ""
			port = -1
			prefix = ""
		else:
			if ss > 1:
				prefix = "/" + s[1]
			s = s[0].split(":", false, 1)
			ss = s.size()
			port = s[1].to_int() if ss > 1 and s[1].is_valid_int() else -1
			host = protocol + ("" if ss == 0 else s[0])


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


func apply_constraints(r: HTTPManagerRoute) -> void:
	for c in _current_constraints():
		c.handle(r)


func _current_constraints() -> Array[HTTPManagerConstraint]:
	if constraint_current_set < 0 or constraint_current_set >= constraint_sets.size():
		return []
	return constraint_sets[constraint_current_set].constraints


func parse_query(query: Dictionary) -> String:
	var s := ""
	for key in query:
		s += "&"
		var value = query[key]
		match typeof(value):
			TYPE_ARRAY, TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
				var t := ""
				if url_param_array_format == ArrayParamFormat.MULTIPLE:
					for a in value:
						t += str("&", key, "=", str(a).uri_encode())
					s += t.substr(1)
				elif url_param_array_format == ArrayParamFormat.SQUARE_BRACKET_EMPTY:
					for a in value:
						t += str("&", key, "[]=", str(a).uri_encode())
					s += t.substr(1)
				elif url_param_array_format == ArrayParamFormat.SQUARE_BRACKET_INDEX:
					for i in range(value.size()):
						t += str("&", key, "[", i, "]=", str(value[i]).uri_encode())
					s += t.substr(1)
				elif url_param_array_format == ArrayParamFormat.ENCODED_SQUARE_BRACKET_EMPTY:
					for i in range(value.size()):
						t += str("&", key, "%5B%5D=", str(value[i]).uri_encode())
					s += t.substr(1)
				elif url_param_array_format == ArrayParamFormat.ENCODED_SQUARE_BRACKET_INDEX:
					for i in range(value.size()):
						t += str("&", key, "%5B", i, "%5D=", str(value[i]).uri_encode())
					s += t.substr(1)
				elif url_param_array_format == ArrayParamFormat.COMMA_SEPARATED:
					s += str(key, "=", " ".join(Array(value)).uri_encode())
				elif url_param_array_format == ArrayParamFormat.SPACE_SEPARATED:
					for a in value:
						t += "," + str(a).uri_encode()
					s += str(key, "=", t.substr(1))
			TYPE_NIL:
				s += str(key)
			TYPE_BOOL:
				s += str(key, "=", url_param_bool_true if value else url_param_bool_false)
			_:
				s += str(key, "=", str(value).uri_encode())
	
	return s if s.is_empty() else "?" + s.substr(1)
