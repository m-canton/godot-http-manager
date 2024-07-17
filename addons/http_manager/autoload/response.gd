class_name HTTPManagerResponse extends RefCounted

var body: PackedByteArray
var code := HTTPClient.RESPONSE_OK
var headers := {}


func parse() -> Variant:
	var content_type: String = headers.get("Content-Type", "")
	if content_type.begins_with("application/json"):
		return JSON.parse_string(body.get_string_from_utf8())
	elif content_type.begins_with("image/"):
		content_type = content_type.substr("image/".length())
		var image := Image.new()
		var error := FAILED
		if content_type.begins_with("webp"):
			error = image.load_webp_from_buffer(body)
		elif content_type.begins_with("png"):
			error = image.load_png_from_buffer(body)
		elif content_type.begins_with("jpeg"):
			error = image.load_jpg_from_buffer(body)
		elif content_type.begins_with("x-tga"):
			error = image.load_tga_from_buffer(body)
		elif content_type.begins_with("bmp"):
			error = image.load_bmp_from_buffer(body)
		if error == OK:
			return image
	return null
