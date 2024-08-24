@tool
class_name HTTPManagerRoute extends Resource

## HTTPManager route resource.
## 
## Defines a client route to use with HTTPManagerRequest.

## Auth types.
enum AuthType {
	NONE, ## No Auth Route.
	OAUTH2_CODE, ## OAuth 2.0 Code Authorization Route.
	OAUTH2_TOKEN, ## OAuth 2.0 Access Token Route.
	OAUTH2_CHECK, ## Use OAuth 2.0 credentials.
	API_KEY_CHECK, ## Use API key credential.
}

## Method enums. See [enum HTTPClient.Method].
enum Method {
	GET,
	HEAD,
	POST,
	PUT,
	DELETE,
	OPTIONS,
	TRACE,
	CONNECT,
	PATCH,
}

enum Encoding {
	GZIP,
	DEFLATE,
}

## Client that uses this route.
@export var client: HTTPManagerClient
## URI pattern. It must start with [code]/[/code]. You can set url param with
## [code]{}[/code].[br]
## [b]Example:[/b] [code]/objects/{id}/{edit?}[/code]. [code]id[/code] is
## required but [code]edit[/code] is optional (closed with [code]?}[/code]).
@export var uri_pattern := ""
## Route description or notes.
@export_multiline var description := ""
## Default headers for this route.
@export var headers: PackedStringArray
## Method for this route.
@export var method := Method.GET
## Accept-Encoding header.
@export var encodings: Array[Encoding]
## Request priority. Lower values are first in the client queue.
@export var priority := 0

@export_group("Auth", "auth_")
## Auth type.
@export var auth_type := AuthType.NONE:
	set(value):
		if auth_type != value:
			auth_type = value
			notify_property_list_changed()
## Auth route.
var auth_route: HTTPManagerRoute

## Handles auth properties.
func _validate_property(property: Dictionary) -> void:
	if property.name == "auth_route":
		if auth_type in [AuthType.OAUTH2_CHECK, AuthType.OAUTH2_CODE]:
			property.usage |= PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
			property.hint = PROPERTY_HINT_RESOURCE_TYPE
			property.hint_string = "HTTPManagerRoute"

## Creates a request to this route. Parses URI pattern with url params.
func create_request(url_params := {}) -> HTTPManagerRequest:
	var r := HTTPManagerRequest.new()
	r.route = self
	
	if not _validate_auth():
		r.valid = false
		return r
	
	for h in headers:
		if not h in r.headers:
			r.headers.append(h)
	
	if not client:
		push_warning("Invalid request. Client is null.")
		r.valid = false
		return r
	
	for h in client.headers:
		if not h in r.headers:
			r.headers.append(h)
	
	# Accept-Encoding header
	var encoding_strings: PackedStringArray
	for e in encodings:
		if e == Encoding.GZIP:
			if not encoding_strings.has("gzip"):
				encoding_strings.append("gzip")
		elif e == Encoding.DEFLATE:
			if not encoding_strings.has("deflate"):
				encoding_strings.append("deflate")
		else:
			continue
	if encoding_strings:
		r.add_header("Accept-Encoding: " + ", ".join(encoding_strings))
	
	if r.set_url_params(url_params):
		push_warning("Invalid request. Invalid url params.")
		r.valid = false
	
	return r

## Checks if auth property group is valid.
func _validate_auth() -> bool:
	## Code requires Token.
	if auth_type == AuthType.OAUTH2_CODE:
		if not auth_route or auth_route.auth_type != AuthType.OAUTH2_TOKEN:
			push_warning("'auth_route' must be OAuth 2.0 Token type: ", resource_path)
			return false
	
	## Check requires Code. It uses access token if it exists.
	if auth_type == AuthType.OAUTH2_CHECK:
		if not auth_route or auth_route.auth_type != AuthType.OAUTH2_CODE:
			push_warning("'auth_route' must be OAuth 2.0 Authorization Code type: ", resource_path)
			return false
	
	return true
