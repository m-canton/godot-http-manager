class_name HTTPManagerResponse extends HTTPManagerStream

## HTTP Manager Response
## 
## Response from a HTTP Manager request. It parses data using Content-Type
## header.

## Code.
var code := 0
## Indicates if this response is successful.
var successful := false

## See [method HTTPManagerStream].
func add_header(new_header: String) -> HTTPManagerResponse:
	return super(new_header)

## Returns parsed body using the indicated mimetype or Content-Type header.
func parse(mimetype := MIME.Type.NONE, attributes := {}) -> Variant:
	if mimetype != MIME.Type.NONE:
		return _parse_body(mimetype, attributes)
	
	var ct := get_content_type()
	if ct == "": return null
	return _parse_body(MIME.string_to_type(ct), MIME.get_attributes(ct))

## Returns Content-Type header value.
func get_content_type() -> String:
	return get_header("Content-Type")

## Returns header value. Empty if it does not exist.
func get_header(header_name: String) -> String:
	header_name += ":"
	for h in headers:
		if h.begins_with(header_name):
			return h.substr(header_name.length()).strip_edges()
	return ""

## Erases a header.
func erase_header(header_name: String) -> void:
	for i in range(headers.size()):
		if headers[i].begins_with(header_name):
			headers.remove_at(i)
			return

## Handles body type to use the right [MIME] method.
func _parse_body(mimetype: MIME.Type, attributes := {}) -> Variant:
	if body is PackedByteArray:
		var ce := get_header("Content-Encoding")
		if ce != "":
			for e in ce.split(",", false):
				e = e.strip_edges()
				if e == "gzip":
					print("Content-Encoding: gzip")
					body = body.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
				elif e == "deflate":
					print("Content-Encoding: deflate")
					body = body.decompress_dynamic(-1, FileAccess.COMPRESSION_DEFLATE)
				else:
					push_error("Invalid Content-Encoding: ", e)
					return null
			erase_header("Content-Encoding")
			
		return MIME.buffer_to_var(body, mimetype, attributes)
	
	if body is String:
		return MIME.string_to_var(body, mimetype, attributes)
	
	if body == null:
		return null
	
	return body
