class_name HTTPManagerResponse extends RefCounted

## Body must be PackedByteArray or 
var body
var code := 0
var successful := false
var headers := PackedStringArray()

## Returns parsed body using the indicated mimetype or Content-Type header.
func parse(mimetype := MIME.Type.NONE, attributes := {}) -> Variant:
	if mimetype != MIME.Type.NONE:
		return _parse_body(mimetype, attributes)
	
	for h in headers:
		if h.begins_with("Content-Type:"):
			var ts := h.substr(13).strip_edges()
			return _parse_body(MIME.string_to_type(ts), MIME.get_attributes(ts))
	
	return null

## Handles body type to use the right [MIME] method.
func _parse_body(mimetype: MIME.Type, attributes := {}) -> Variant:
	if body is PackedByteArray:
		return MIME.buffer_to_var(body, mimetype, attributes)
	
	if body is String:
		return MIME.string_to_var(body, mimetype, attributes)
	
	if body == null:
		return null
	
	return body
