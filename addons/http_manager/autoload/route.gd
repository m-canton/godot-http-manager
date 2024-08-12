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
@export_multiline var description := ""
## Default headers for this route.
@export var headers: PackedStringArray = []
## Method for this route.
@export var method := Method.GET
## Request priority. Lower values are first in the client queue.
@export var priority := 0


## Creates a request to this route. Method name can change.
## @experimental
func create_request(url_params := {}, body = null, body_type := MIME.Type.NONE) -> HTTPManagerRequest:
	var r := HTTPManagerRequest.new()
	
	if not client:
		push_error("Creating a request from route with  null client.")
		return null
	
	r.route = self
	
	for h in headers:
		if not h in r.headers:
			r.headers.append(h)
	
	for h in client.headers:
		if not h in r.headers:
			r.headers.append(h)
	
	if r.set_url_params(url_params):
		return null
	
	if body_type != MIME.Type.NONE:
		r.with_body(body, body_type)
	
	return r
