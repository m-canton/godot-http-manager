class_name HTTPManagerResponse extends RefCounted

var body: PackedByteArray
var code := HTTPClient.RESPONSE_OK
var successful := false
var headers := PackedStringArray()


func parse() -> Variant:
	for h in headers:
		if h.begins_with("Content-Type:"):
			var ts := h.substr(14)
			return MIME.buffer_to_var(body, MIME.string_to_type(ts), MIME.get_attributes(ts))
	return null
