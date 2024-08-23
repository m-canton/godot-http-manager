class_name HTML extends RefCounted


const FontSize := {
	medium = 16,
	large = 18,
}

## Attribute dictionary to string. Set [code]null[/code] value not to add
## value.
static func attributes_to_string(attributes: Dictionary, space := false) -> String:
	var s := ""
	for key in attributes:
		var value = attributes[key]
		s += " " + key
		if value != null:
			s += str("=\"", value, "\"")
	return s if space else s.substr(1)

## Parses style attribute string to [Dictionary].
static func attributes_from_style_string(style: String) -> Dictionary:
	var dict := {}
	for p in style.split(";", false):
		p = p.strip_edges()
		if p.is_empty():
			continue
		var pp := p.split(":")
		if pp.size() == 1:
			dict[pp[0].strip_edges()] = ""
		else:
			dict[pp[0].strip_edges()] = pp[1].strip_edges()
	return dict

## Parses HTML code to type in [RichTextLabel].
static func type_content_from_html(label: RichTextLabel, html: String) -> Error:
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
						label.push_meta(attributes.get("href", ""))
						count += 1
					"p":
						attributes.get("style", "")
						label.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
						count += 1
					"span":
						var style := HTML.attributes_from_style_string(attributes.get("style", ""))
						if style.has("font-size"):
							var fsize: int = FontSize.get(style.get("font-size"), 0)
							if fsize == 0:
								push_warning("Font size not supported: ", FontSize.get("font-size"))
							else:
								if fsize != FontSize.medium:
									label.push_font_size(fsize)
									count += 1
					"img":
						var ikey := Time.get_ticks_usec()
						var image := Image.create(1, 1, true, Image.FORMAT_ASTC_4x4)
						var texture := ImageTexture.create_from_image(image)
						label.add_image(texture, 0, 0, Color.WHITE, INLINE_ALIGNMENT_CENTER, Rect2(), ikey)
						HTTPManager.download(attributes.get("src", ""))
						print("+Img: ", attributes)
					"br":
						label.newline()
					"div":
						print("+Div: ", attributes)
						label.newline()
						count += 1
					_:
						print("Node no handled: ", parser.get_node_name())
						print("- Attributes: ", attributes)
						count += 1
				open_tags.append(parser.get_node_name() + ":" + str(count))
			XMLParser.NODE_ELEMENT_END:
				var otag := open_tags[-1].split(":", false)
				for i in range(otag[1].to_int()):
					label.pop()
				open_tags.remove_at(open_tags.size() - 1)
			XMLParser.NODE_TEXT:
				label.add_text(parser.get_node_data())
			#XMLParser.NODE_COMMENT, XMLParser.NODE_CDATA, XMLParser.NODE_UNKNOWN: pass
	
	return OK

## Updates [RichTextLabel] image from response.
static func update_label_image_from_response(response: HTTPManagerResponse, label: RichTextLabel, key: int) -> void:
	label.update_image(key, RichTextLabel.ImageUpdateMask.UPDATE_TEXTURE, ImageTexture.create_from_image(response.parse()))
