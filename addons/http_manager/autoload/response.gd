class_name HTTPManagerResponse extends RefCounted

var body: PackedByteArray
var code := HTTPClient.RESPONSE_OK
var successful := false
var headers := {}


var _parse_content_type := ""


func parse() -> Variant:
	_parse_content_type = headers.get("Content-Type", "")
	if _check_type("application"):
		if _check_subtype("json"):
			return JSON.parse_string(body.get_string_from_utf8())
	elif _check_type("text"):
		if _check_subtype("html"):
			return body.get_string_from_utf8()
	elif _check_type("image"):
		var image := Image.new()
		var error := FAILED
		if _check_subtype("webp"):
			error = image.load_webp_from_buffer(body)
		elif _check_subtype("png"):
			error = image.load_png_from_buffer(body)
		elif _check_subtype("jpeg"):
			error = image.load_jpg_from_buffer(body)
		elif _check_subtype("x-tga"):
			error = image.load_tga_from_buffer(body)
		elif _check_subtype("bmp"):
			error = image.load_bmp_from_buffer(body)
		if error == OK:
			return image
	push_warning("This Content-Type cannot be parsed: ", headers.get("Content-Type", ""))
	return null


func _check_type(s: String, add_slash := true) -> bool:
	if add_slash:
		s += "/"
	
	if _parse_content_type.begins_with(s):
		_parse_content_type = _parse_content_type.substr(s.length())
		return true
	
	return false


func _check_subtype(s: String) -> bool:
	if _parse_content_type == s:
		_parse_content_type = _parse_content_type.substr(s.length())
		return true
	
	if _parse_content_type.begins_with(s + ";"):
		_parse_content_type = _parse_content_type.substr(s.length() + 1).strip_edges(true, false)
		return true
	
	return false
