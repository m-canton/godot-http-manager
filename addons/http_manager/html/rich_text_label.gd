class_name HTMLRichTextLabel extends RichTextLabel


const FontSize := {
	medium = 16,
	large = 18,
}

## Pending images. You can download and update the images with
## [method download_image].
var pending_images := {}

## Clears [member pending_images] and text and calls [method add_html].
func set_html(html: String) -> Error:
	clear()
	pending_images.clear()
	scroll_to_line(0)
	return add_html(html)

## Adds BBCode elements from HTML code.
func add_html(html: String) -> Error:
	var parser := XMLParser.new()
	var error := parser.open_buffer(html.to_utf8_buffer())
	if error:
		push_error(error_string(error))
		return error
	
	var open_tags := PackedStringArray()
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var attributes := {}
				var count := 0
				for i in range(parser.get_attribute_count()):
					attributes[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				match parser.get_node_name():
					"a":
						push_meta(attributes.get("href", ""))
						count += 1
					"p":
						attributes.get("style", "")
						push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
						count += 1
					"span":
						var style := HTML.attributes_from_style_string(attributes.get("style", ""))
						if style.has("font-size"):
							var fsize: int = FontSize.get(style.get("font-size"), 0)
							if fsize == 0:
								push_warning("Font size not supported: ", FontSize.get("font-size"))
							else:
								if fsize != FontSize.medium:
									push_font_size(fsize)
									count += 1
					"img":
						var ikey := Time.get_ticks_usec()
						var image := Image.create(1, 1, true, Image.FORMAT_ASTC_4x4)
						var texture := ImageTexture.create_from_image(image)
						add_image(texture, 0, 0, Color.WHITE, INLINE_ALIGNMENT_CENTER, Rect2(), ikey)
						pending_images[ikey] = attributes
						print("+Img: ", attributes)
					"br":
						newline()
					"div":
						print("+Div: ", attributes)
						newline()
						count += 1
					_:
						print("Node no handled: ", parser.get_node_name())
						print("- Attributes: ", attributes)
						count += 1
				open_tags.append(parser.get_node_name() + ":" + str(count))
			XMLParser.NODE_ELEMENT_END:
				var otag := open_tags[-1].split(":", false)
				for i in range(otag[1].to_int()):
					pop()
				open_tags.remove_at(open_tags.size() - 1)
			XMLParser.NODE_TEXT:
				add_text(parser.get_node_data())
			#XMLParser.NODE_COMMENT, XMLParser.NODE_CDATA, XMLParser.NODE_UNKNOWN: pass
	
	return OK

## Returns [code]true[/code] if there are pending images to download.
func can_download_images() -> bool:
	return not pending_images.is_empty()

## Downloads an image.
func download_image(key: int, on_complete = null) -> Error:
	var dict = pending_images.get(key)
	if dict is Dictionary:
		dict["on_complete_listener"] = on_complete
		return HTTPManagerDownload.create_from_url(dict.get("src", "")).start(_on_image_downloaded.bind(key))
	pending_images.erase(key)
	return ERR_DOES_NOT_EXIST

## Downloads the next image. [param on_complete] is a [Callable] with a
## image key and success params.
func download_next_image(on_complete = null) -> Error:
	if pending_images.is_empty():
		return ERR_FILE_EOF
	
	var key: int = pending_images.keys()[0]
	return download_image(key, on_complete)

## Updates the image on downloaded.
func _on_image_downloaded(response: HTTPManagerResponse, key: int) -> void:
	if not pending_images.has(key):
		return
	
	var dict: Dictionary = pending_images[key]
	var success := false
	
	var image = response.parse()
	if image is Image:
		#var isize: Vector2i = image.get_size()
		#isize.aspect()
		#TODO fit image
		success = true
		update_image(key, RichTextLabel.ImageUpdateMask.UPDATE_TEXTURE, ImageTexture.create_from_image(image))
	
	pending_images.erase(key)
	var on_complete = dict.get("on_complete_listener")
	if on_complete is Callable:
		on_complete.call(key, success)
