class_name HTTPManagerClientParsedUrl extends Node

## URL scheme.
var scheme := ""
## URL domain.
var domain := ""
## URL port.
var port := -1
## URL path.
var path := ""
## URL query.
var query := "":
	set(value):
		if query != value:
			query = value
			_query_changed = true
## URL fragment.
var fragment := ""
## Indicates if [member query] has changed.
var _query_changed := false
var _parsed_query: PackedStringArray

## Returns URL string.
func get_url() -> String:
	var s := get_host()
	if port != -1: s += ":" + str(port)
	return s + get_full_path()

## Returns scheme and host with delimiter.
func get_host() -> String:
	if scheme.is_empty():
		return domain
	return scheme + "://" + domain

## Returns path, query and fragment with delimiters.
func get_full_path() -> String:
	var s := path
	if query != "": s += "?" + query
	if fragment != "": s += "#" + fragment
	return s

## Returns query as [PackedStringArray].
func get_query_array() -> PackedStringArray:
	if _query_changed:
		_parsed_query = query.split("&", false)
	return _parsed_query

## Returns query as [Dictionary].
func get_query_dict() -> Dictionary:
	var dict := {}
	for p in get_query_array():
		if p.is_empty(): continue
		var pp := p.split("=")
		if pp[0].is_empty(): continue
		if pp.size() == 1:
			dict[pp[0]] = null
		else:
			dict[pp[0]] = pp[1]
	return dict

## Returns a param value if it exists in the query.
func find_query_param(param: String) -> String:
	get_query_array()
	var key := param + "="
	for p in _parsed_query:
		if p.begins_with(key):
			return p.substr(key.length())
	return ""

## Prints URL parts.
func print_parts() -> void:
	print("Scheme: ", scheme)
	print("Domain: ", domain)
	print("Port: ", port)
	print("Path: ", path)
	print("Query: ")
	var dict := get_query_dict()
	for key in dict:
		print("- ", key, ": ", dict[key])
	print("Fragment: ", fragment)
