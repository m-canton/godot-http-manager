class_name HTTPManagerRequest extends RefCounted

signal completed(response: HTTPManagerResponse)

## HTTPManager Request class.
## 
## This class requests from a [HTTPManagerRoute] according to client
## restrictions. Use [method create_from_route] to create a instance because
## it adds the client and route headers to this and sets the route for you.

## Route resource.
var route: HTTPManagerRoute
## Overrides route priority. See [HTTPManagerRoute.priority].
var priority := -1
## Headers.
var headers := PackedStringArray()
## Authentication.
var use_auth := false
## Body.
var body := ""
## Parsed URI.
var _parsed_uri := ""

## TLS Options.
var tls_options: TLSOptions

## Emits [signal completed] signal with the response. Used by HTTPManager when
## response is completed or gets a error.
func complete(response: HTTPManagerResponse) -> void:
	completed.emit(response)

## Get endpoint uri with url params.
func get_parsed_uri() -> String:
	if route:
		return _parsed_uri
	return ""


#region Authentication
## Adds Basic Authentication header.
func with_basic_auth(username: String, password: String) -> HTTPManagerRequest:
	_with_auth("Basic " + Marshalls.utf8_to_base64(username + ":" + password))
	return self

## Adds Basic Authentication header. Not implementet yet.
## @experimental
func with_diggest_auth(_username: String, _password: String) -> HTTPManagerRequest:
	push_error("Not implemented yet.")
	return self

## Adds Authorization header.
func _with_auth(type_credentials_string: String) -> void:
	headers.append("Authorization: " + type_credentials_string)
	use_auth = true
#endregion

## Adds this request to client queue.
## @experimental
func start(query := {}) -> HTTPManagerRequest:
	var parts := route.uri_pattern.split("/")
	var parsed_parts := PackedStringArray()
	
	var used_params := PackedStringArray()
	
	for part in parts:
		var parsed_part := ""
		if part in used_params:
			push_error("Duplicated url param. Use different names in 'uri_patern': ", route.resource_path)
			return self
		elif part.begins_with("{"):
			if part.ends_with("?}"):
				part = part.substr(1, part.length() - 3)
				
				if not query.has(part):
					continue
			elif part.ends_with("}"):
				part = part.substr(1, part.length() - 2)
				
				if not query.has(part):
					push_error("Route requires '%s' param: %s" % [part, route.resource_path])
					return self
			else:
				push_error("'{' does not close in 'uri_pattern': ", route.resource_path)
				return self
			
			var query_value = query.get(part)
			used_params.append(part)
			query.erase(part)
			
			if query_value is int:
				parsed_part = str(parsed_part)
			elif query_value is StringName or query_value is String:
				parsed_part = String(query_value)
			else:
				push_error("'%s' url param must be integer or string: %s" % [part, route.resource_path])
				return self
		else:
			parsed_part = part
		parsed_parts.append(parsed_part)
	
	_parsed_uri = "/".join(parsed_parts) + route.client.parse_query(query)
	print(_parsed_uri)
	
	var _error := HTTPManager.request(self)
	
	return self

## Use only Array, Dictionary or String. Don't use Packed*Array types.
## @experimental
func with_body(b) -> HTTPManagerRequest:
	if b is Array or b is Dictionary:
		body = JSON.stringify(b, "", false)
	elif b is String:
		body = b
	else:
		push_warning("Not valid body")
	return self

## Creates a request instance from a route.
static func create_from_route(r: HTTPManagerRoute) -> HTTPManagerRequest:
	var re := HTTPManagerRequest.new()
	if not r:
		push_error("Creating a request with null route.")
		return null
	
	if not r.client:
		push_error("Creating a request from route with  null client.")
		return null
	
	re.route = r
	re.headers.append_array(r.headers)
	re.headers.append_array(r.client.headers)
	return re
