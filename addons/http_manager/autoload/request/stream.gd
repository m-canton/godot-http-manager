class_name HTTPManagerStream extends RefCounted


## Headers.
var headers: PackedStringArray
## Body.
var body
var _body_buffer: PackedByteArray

## Adds a new header. It replaces the value if it already exists.
func add_header(new_header: String) -> HTTPManagerStream:
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
