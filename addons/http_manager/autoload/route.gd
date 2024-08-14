class_name HTTPManagerRoute extends Resource

## HTTPManager route resource.
## 
## Defines a client route to use with HTTPManagerRequest.

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
@export var headers: PackedStringArray = []
## Method for this route.
@export var method := Method.GET
## Request priority. Lower values are first in the client queue.
@export var priority := 0


## Creates a request to this route. Method name can change.
## @experimental
func create_request(url_params := {}, body = null, content_type := MIME.Type.NONE) -> HTTPManagerRequest:
	var r := HTTPManagerRequest.new()
	
	r.route = self
	
	for h in headers:
		if not h in r.headers:
			r.headers.append(h)
	
	if not client:
		r.valid = false
		return r
	
	for h in client.headers:
		if not h in r.headers:
			r.headers.append(h)
	
	if r.set_url_params(url_params) == OK:
		r.set_body(body, content_type)
	else:
		r.valid = false
	
	return r
