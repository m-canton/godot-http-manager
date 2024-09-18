class_name HTTPManagerStream extends RefCounted


## Headers.
var headers: PackedStringArray
## Body.
var body
var _mimetype := MIME.Type.NONE
var _attributes := {}

## Adds a new header. It change the value if it already exists.
func set_header(new_header: String) -> HTTPManagerStream:
	var header_name := new_header.get_slice(":", 0) + ":"
	
	var i := headers.size() - 1
	
	while i >= 0:
		if headers[i].begins_with(header_name):
			headers[i] = new_header
			return self
		i -= 1
	
	headers.append(new_header)
	
	return self

## Returns header value. Empty if it does not exist.
func get_header(header_name: String) -> String:
	header_name += ":"
	for h in headers:
		if h.begins_with(header_name):
			return h.substr(header_name.length()).strip_edges()
	return ""

## Returns body as [PackedByteArray].
func get_body_as_buffer() -> PackedByteArray:
	if body is PackedByteArray:
		return body
	
	return MIME.var_to_buffer(body, _mimetype, _attributes)

## Returns body as [String].
func get_body_as_string() -> String:
	if body is String:
		return body
	
	return MIME.var_to_string(body, _mimetype, _attributes)
