class_name HTTPManagerResponse extends Node

var data: PackedByteArray
var error_code := 0
var error_message := ""
var headers := PackedStringArray()


func has_error() -> bool:
	return error_message.is_empty()


func get_as_string() -> String:
	if data.is_empty():
		return ""
	return data.get_string_from_utf8()


func get_content_type() -> Dictionary:
	for h in headers:
		if h.begins_with("Content-Type: "):
			h = h.trim_prefix("Content-Type: ")
			var dict := {}
			for key_value in h.split(";"):
				if dict.is_empty():
					dict["type"] = key_value.strip_edges()
				else:
					var array := key_value.split("=")
					dict[array[0].strip_edges()] = array[1].strip_edges()
			return dict
	return {}


func parse() -> Variant:
	var content_dict := get_content_type()
	match content_dict.get("type", ""):
		"application/json":
			match content_dict.charset.to_lower():
				"utf-8":
					return JSON.parse_string(data.get_string_from_utf8())
				"utf-16":
					return JSON.parse_string(data.get_string_from_utf16())
				"utf-32":
					return JSON.parse_string(data.get_string_from_utf32())
		"image/bmp": # "image/gif", "image/tiff", "image/svg+xml", "image/x-icon"
			var image := Image.new()
			if image.load_bmp_from_buffer(data) == OK:
				return image
		"image/jpeg":
			var image := Image.new()
			if image.load_jpg_from_buffer(data) == OK:
				return image
		"image/png":
			var image := Image.new()
			if image.load_png_from_buffer(data) == OK:
				return image
		"image/webp":
			var image := Image.new()
			if image.load_webp_from_buffer(data) == OK:
				return image
		"image/x-tga":
			var image := Image.new()
			if image.load_tga_from_buffer(data) == OK:
				return image
	return null
