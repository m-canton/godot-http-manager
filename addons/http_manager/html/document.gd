class_name HTMLDocument extends RefCounted


## HTML Document class.
## 
## Creates and loads HTML documents.
## @experimental


## Default block indent.
const BLOCK_INDENT := 1
## Default indent char.
const INDENT_CHAR := "\t"

## Current open tags. Use [method pop] to close the last open tag.
var _open_tags: Array[Dictionary] = []
## Current block indent.
var _indent := 0
## Indicates if current tag is added inline.
var _inline := false
## Document content.
var text := ""


func add_text(new_text: String) -> HTMLDocument:
	return _add_text(new_text)


func add_comment(new_text: String) -> HTMLDocument:
	return _add_text("<!-- " + new_text + " -->\n")


func add_doctype(new_text := "html") -> HTMLDocument:
	return _add_text("<!DOCTYPE " + new_text + ">\n")


func add_meta(attributes := {}) -> HTMLDocument:
	return add_tag("meta", attributes)

## Adds a inline tag in the current open tag.
func add_tag(name: String, attributes := {}, options := {}) -> HTMLDocument:
	text += str(INDENT_CHAR.repeat(_indent), "<", name, HTML.attributes_to_string(attributes, true), "/" if options.get("slash", false) else "", ">")
	if not _inline: text += "\n"
	return self

## Clears the document.
func clear() -> void:
	text = ""
	_indent = 0
	_inline = false
	_open_tags.clear()

## Erases the last character in [member text].
func backspace() -> HTMLDocument:
	text = text.erase(text.length() - 1)
	return self


func get_open_tags() -> Array:
	return _open_tags


func newline() -> HTMLDocument:
	text += "\n"
	return self


func start_p(attributes := {}, options := {}) -> HTMLDocument:
	options["inline"] = options.get("inline", true)
	return start_tag("p", attributes, options)


func start_body(attributes := {}) -> HTMLDocument:
	return newline().start_tag("body", attributes)


func start_html(attributes := {}) -> HTMLDocument:
	return start_tag("html", attributes, { indent = 0 }).newline()


func start_head(attributes := {}) -> HTMLDocument:
	return start_tag("head", attributes)


func start_header(level := 1, attributes := {}, options := {}) -> HTMLDocument:
	options["inline"] = options.get("inline", true)
	start_tag(str("h", clamp(level, 1, 6)), attributes, options)
	return self


## Adds a block tag in the current open tag.
func start_tag(name: String, attributes := {}, options := {}) -> HTMLDocument:
	text += str(INDENT_CHAR.repeat(_indent), "<", name, HTML.attributes_to_string(attributes, true), ">")
	
	_inline = options.get("inline", false)
	if not _inline:
		_indent += options.get("indent", BLOCK_INDENT)
		text += "\n"
	_open_tags.append({ name = name, options = options })
	
	return self

## Closes the last opent tag. See [member _open_tags].
func close_tag() -> HTMLDocument:
	var n := _open_tags.size()
	if n == 0:
		push_warning("No open tags.")
	else:
		var tag: Dictionary = _open_tags.pop_back()
		text += "</" + tag.name + ">"
		
		if not _inline:
			_indent -= tag.options.get("indent", BLOCK_INDENT)
			text += "\n"
		
		if _open_tags.is_empty():
			_indent = 0
			_inline = false
		else:
			var current_tag: Dictionary = _open_tags[-1]
			_inline = current_tag.options.get("inline", false)
		
		if not _inline:
			text += "\n"
	return self


func _add_text(new_text: String) -> HTMLDocument:
	if not _inline: text += INDENT_CHAR.repeat(_indent)
	text += new_text
	return self


func to_bytes() -> PackedByteArray:
	return text.to_utf8_buffer()


## Loads a [HTMLFile] from .html document.
## @experimental
static func load_from_file(path: String) -> HTMLDocument:
	var doc := HTMLDocument.new()
	doc.text = FileAccess.get_file_as_string(path)
	return doc
