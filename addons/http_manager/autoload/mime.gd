class_name MIME extends RefCounted

## Content Parser using MIME type.
## 
## This class supports some MIME types. More support will be added.

## MIME Types.
enum Type {
	NONE, ## No type
	HTML, ## text/html
	JPG, ## image/jpeg
	JSON, ## application/json
	PNG, ## image/png
	URL_ENCODED, ## application/x-www-form-urlencoded
	TEXT, ## text/plain
	WEBP, ## image/webp
	WEBM_AUDIO, ## audio/webm
	WEBM_VIDEO, ## video/webm
}

## MIME Type map.
const TypeDict := {
	"audio": {
		"webm": Type.WEBM_AUDIO,
	},
	"application": {
		"json": Type.JSON,
		"x-www-form-urlencoded": Type.URL_ENCODED,
	},
	"image": {
		"jpeg": Type.JPG,
		"png": Type.PNG,
		"webp": Type.WEBP,
	},
	"text": {
		"html": Type.HTML,
		"plain": Type.TEXT,
	},
	"video": {
		"webm": Type.WEBM_VIDEO,
	},
}

## Returns MIME type string from [enum Type].
static func type_to_string(type: Type, attributes := {}) -> String:
	for tkey: String in TypeDict:
		for skey: String in TypeDict[tkey]:
			if TypeDict[tkey][skey] == type:
				var s := tkey + "/" + skey
				for key in attributes:
					s += str("; ", key, "=", attributes[key])
				return s
	return ""

## Returns MIME type from [String].
static func string_to_type(mimetype: String) -> Type:
	var i := mimetype.find(";")
	if i != -1:
		mimetype = mimetype.substr(0, i)
	
	var s := mimetype.split("/")
	if s.size() != 2:
		push_warning("Invalid MIME type: ", mimetype)
		return Type.NONE
	
	return TypeDict.get(s[0], {}).get(s[1], Type.NONE)

## Returns MIME type attributes as [Dictionary].
static func get_attributes(mimetype: String) -> Dictionary:
	var attributes := {}
	for part in mimetype.split(";", false).slice(1):
		var sp := part.split("=")
		if sp.size() == 2:
			attributes[sp[0].strip_edges()] = sp[1].strip_edges()
		else:
			push_warning("Invalid attribute: ", part)
	return attributes

## Returns Accept header.
static func type_to_accept(mime: MIME.Type, attributes := {}) -> String:
	var s := MIME.type_to_string(mime, attributes)
	if s.is_empty():
		return s
	return "Accept: " + s

## Returns Content-Type header.
static func type_to_content_type(mime: MIME.Type, attributes := {}) -> String:
	var s := MIME.type_to_string(mime, attributes)
	if s.is_empty():
		return s
	return "Content-Type: " + s
#endregion

#region Buffer
## Converts buffer to variant.
static func buffer_to_var(buffer: PackedByteArray, type := Type.NONE, attributes := {}) -> Variant:
	if type == Type.JSON:
		return JSON.parse_string(buffer.get_string_from_utf8())
	if type in [Type.HTML, Type.TEXT]:
		return buffer.get_string_from_utf8()
	if type == Type.JPG:
		var image := Image.new()
		return image if image.load_jpg_from_buffer(buffer) == OK else null
	if type == Type.PNG:
		var image := Image.new()
		return image if image.load_png_from_buffer(buffer) == OK else null
	if type == Type.WEBP:
		var image := Image.new()
		return image if image.load_webp_from_buffer(buffer) == OK else null
	push_warning("Type not supported.")
	return []

## Converts variant to buffer.
static func var_to_buffer(value, type := Type.NONE, attributes := {}) -> PackedByteArray:
	if type == Type.JSON:
		return var_to_string(value).to_utf8_buffer()
	elif type in [Type.URL_ENCODED, Type.HTML, Type.TEXT]:
		return value.to_utf8_buffer() if value is String else []
	elif type == Type.JPG:
		if value is Texture2D:
			value = value.get_image()
		if value is Image:
			return value.save_jpg_to_buffer()
	elif type == Type.PNG:
		if value is Texture2D:
			value = value.get_image()
		if value is Image:
			return value.save_png_to_buffer()
	elif type == Type.WEBP:
		if value is Texture2D:
			value = value.get_image()
		if value is Image:
			return value.save_jpg_to_buffer()
	else:
		push_warning("This variant cannot be converted to a buffer.")
	return []

## Converts [Variant] to [String].
static func var_to_string(value, type := Type.NONE, attributes := {}) -> String:
	if type == Type.JSON:
		return value if value is String else JSON.stringify(value, "", false)
	elif type in [Type.HTML, Type.TEXT, Type.URL_ENCODED]:
		return value if value is String else ""
	elif type in [Type.JPG, Type.PNG, Type.WEBP]:
		return Marshalls.raw_to_base64(value if value is PackedByteArray else var_to_buffer(value, type, attributes))
	elif value is String:
		return value
	else:
		push_warning("This variant cannot be converted to a string.")
	return ""
