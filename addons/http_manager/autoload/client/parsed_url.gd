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
var _query := ""
## URL fragment.
var fragment := ""
## Indicates if [member query] has changed.
var _query_changed := false
## Query params.
var _query_array: PackedStringArray

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
	if _query != "": s += "?" + _query
	if fragment != "": s += "#" + fragment
	return s

## Returns query string.
func get_query_string() -> String:
	return _query

## Returns query as [PackedStringArray].
func get_query_array() -> PackedStringArray:
	if _query_changed:
		_query_array = _query.split("&", false)
	return _query_array

## Returns query as [Dictionary].
func get_query_dict() -> Dictionary:
	var dict := {}
	for p in get_query_array():
		if p.is_empty(): continue
		var pp := p.split("=")
		if pp[0].is_empty(): continue
		dict[pp[0]] = null if pp.size() == 1 else pp[1]
	return dict

## Joins query param to the end. This method does not check if this param
## exists. See [method merge_query] for more control.
func query_param_join(param: String, value) -> void:
	if _query != "": _query += "&"
	var p := str(param, "&", value)
	_query += p
	if not _query_changed: _query_array.append(p)

## Sets query. Accepts [String], [Array], [PackedStringArray], and [Dictionary].
func set_query(new_query) -> void:
	if new_query is String:
		_query = new_query
	elif new_query is Array or new_query is PackedStringArray:
		_query = "&".join(new_query)
	elif new_query is Dictionary:
		var s := ""
		for key in new_query:
			s += str("&", key, "=", new_query[key])
		_query = s.substr(1)
	else:
		push_error("'new_query' type cannot be parsed.")
		return
	_query_changed = true

## Merges query.
func merge_query(new_query: Dictionary, overwrite := true) -> void:
	var dict := get_query_dict()
	dict.merge(new_query, overwrite)
	set_query(dict)

## Returns a param value if it exists in the query.
func find_query_param(param: String) -> String:
	get_query_array()
	var key := param + "="
	for p in _query_array:
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
