class_name HTML extends RefCounted


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
