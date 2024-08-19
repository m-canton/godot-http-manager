class_name HTTPManagerClientParsedUrl extends Node


var scheme := ""
var domain := ""
var port := -1
var path := ""
var query := ""
var fragment := ""

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
