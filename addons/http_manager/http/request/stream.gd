class_name HTTPManagerStream extends RefCounted


## Headers.
var headers: PackedStringArray
## Body.
var body
var _mimetype := MIME.Type.NONE
var _attributes := {}

## Adds a new header. It change the value if it already exists.[br]
## RFC 7230 states header name is case-insensitive.
func set_header(new_header: String, multiple := false) -> HTTPManagerStream:
	var header_name := new_header.get_slice(":", 0)
	
	if not multiple:
		var i := headers.size() - 1
		
		while i >= 0:
			if headers[i].get_slice(":", 0).to_lower() == header_name:
				headers[i] = new_header
				return self
			i -= 1
	
	headers.append(new_header)
	
	return self

## Returns header value as [String]. Empty if it does not exist.[br]
## RFC 7230 states header name is case-insensitive.
func get_header(header_name: String) -> String:
	header_name = header_name.to_lower()
	for h in headers:
		if h.get_slice(":", 0).to_lower() == header_name:
			return h.substr(header_name.length() + 1).strip_edges()
	return ""

## Returns header values. A header can have multiple values ​​either by
## duplicating the name or separating them by commas. Empty if it does not
## exist.[br]
## RFC 7230 states header name is case-insensitive.
func get_header_multiple(header_name: String) -> PackedStringArray:
	var values: PackedStringArray
	header_name = header_name.to_lower()
	for header in headers:
		if header.get_slice(":", 0).to_lower() == header_name:
			var header_values := header.substr(header_name.length() + 1)
			for value in header_values.split(",", false):
				values.append(value.strip_edges())
	return values

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
