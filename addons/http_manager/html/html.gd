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
