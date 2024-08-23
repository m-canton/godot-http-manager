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

enum ClientData {
	TOKEN,
	CACHE,
}

## See [method parse_url].
enum ParsedUrl {
	SCHEME, ## Scheme.
	DOMAIN, ## Domain.
	PORT, ## Port.
	PATH, ## Path.
	QUERY, ## Query.
	FRAGMENT, ## Fragment.
}

## Setting name for client data dir to save data.
const SETTING_NAME_DIR := "addons/http_manager/clients/data_dir"
## Default setting value for clients dir.
const DEFAULT_DIR := "user://addons/http_manager"
## Client file name.
const CLIENT_FILENAME := "client.ini"

static var _url_regex: RegEx

## Base URL. This string cannot end with [code]"/"[/code].[br]
## [b]Example:[/b] [code]"http://localhost:8080/api"[/code].
@export var base_url := ""
## Client description or notes.
@export_multiline var description := ""
## Headers that are added when request starts with this client.
@export var headers: PackedStringArray = []
## Maximum concurrent requests.
@export_range(0, 10, 1, "or_greater") var max_redirects := 3
## Maximum concurrent requests.
@export_range(0, 10, 1, "or_greater") var max_concurrent_requests := 1
## Maximum concurrent downloads.
@export_range(0, 10, 1, "or_greater") var max_concurrent_downloads := 1
## Priority in HTTPManager to make requests.[br]
## [b]Note: [/b] It does nothing yet.
## @experimental
@export var priority := 0

## Client data to store cache references and auth credentials.
@export var data: HTTPManagerClientData

@export_group("URL Params", "url_param_")
## Replaces [code]true[/code] value by this string in url param values.
@export var url_param_bool_true := "1"
## Replaces [code]false[/code] value by this string in url param values.
@export var url_param_bool_false := "0"
## Array format for url param values. See [enum ArrayParamFormat].
@export var url_param_array_format := ArrayParamFormat.MULTIPLE

@export_group("Constraint", "constraint_")
## Active constraint set index. See [member constraint_sets].
@export var constraint_current_set := 0
## Constraint sets. See [HTTPManagerConstraintSet].
@export var constraint_sets: Array[HTTPManagerConstraintSet] = []

## Request queue.
var _queue: Array[HTTPManagerRequest] = []

## Processes constraints.
func process(delta: float) -> bool:
	for c in _current_constraints():
		if c.processing:
			return c.process(delta) and not _queue.is_empty()
	return false

## Removes a request from queue.
func cancel_request(r: HTTPManagerRequest) -> bool:
	var i := _queue.find(r)
	if i == -1: return false
	_queue.remove_at(i)
	return true

## Clears the queue.
func cancel_requests() -> void:
	_queue.clear()

## Appends a request to the queue.
func queue(r: HTTPManagerRequest) -> void:
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

## Returns the next requestand removes it from the queue.
func next() -> HTTPManagerRequest:
	return _queue.pop_front()

## Returns [code]true[/code] if the next request can start depending on the
## constraints.
func can_next() -> bool:
	if _queue.is_empty():
		return false
	
	for c in _current_constraints():
		if not c.check(_queue[-1].route):
			return false
	
	return true

## Returns [code]true[/code] if the request queue is empty.
func is_empty() -> bool:
	return _queue.is_empty()

## Applies restrictions based on the route processed.
func apply_constraints(r: HTTPManagerRoute) -> void:
	for c in _current_constraints():
		c.handle(r)

## Returns the current constraints. See [member constraint_current_set].
func _current_constraints() -> Array[HTTPManagerConstraint]:
	if constraint_current_set < 0 or constraint_current_set >= constraint_sets.size():
		return []
	return constraint_sets[constraint_current_set].constraints

## Returns [member base_url] as [HTTPManagerClientParsedUrl].
func parse_base_url() -> HTTPManagerClientParsedUrl:
	return HTTPManagerClient.parse_url(base_url)

## Returns a query [Dictionary] as [String].
func query_string_from_dict(query: Dictionary) -> String:
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
	
	return s.substr(1)

## Returns clients dir from project settings.
static func get_clients_dir() -> String:
	return ProjectSettings.get_setting(SETTING_NAME_DIR, DEFAULT_DIR)

## Returns URL parts. See [enum ParsedUrl]
static func parse_url(url: String) -> HTTPManagerClientParsedUrl:
	if not _url_regex is RegEx:
		_url_regex = RegEx.create_from_string("(?<scheme>https?):\\/\\/(?<domain>[a-zA-Z0-9\\.\\-]+)(:(?<port>[0-9]+))?(?<path>[^\\?#]*)(\\?(?<query>[^\\?#]*))?(#(?<fragment>[^\\?#]*))?")
	
	var result := _url_regex.search(url)
	if not result:
		push_error("Invalid URL: ", url)
		return null
	
	var parsed_url := HTTPManagerClientParsedUrl.new()
	parsed_url.scheme = result.get_string("scheme")
	parsed_url.domain = result.get_string("domain")
	
	var port_string := result.get_string("port")
	parsed_url.port = -1 if port_string == "" else port_string.to_int()
	
	parsed_url.path = result.get_string("path")
	parsed_url.set_query(result.get_string("query"))
	parsed_url.fragment = result.get_string("fragment")
	return parsed_url
