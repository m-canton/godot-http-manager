class_name HTTPManagerRoute extends Resource

## HTTPManager route resource.
## 
## Defines a client route to use with HTTPManagerRequest.

## JSON MIME type.
const MIMETYPE_JSON := "application/json"
## Url encoded MIME type.
const MIMETYPE_URL_ENCODED := "application/x-www-form-urlencoded"

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
## Default headers for this route.
@export var headers := PackedStringArray()
## Method for this route.
@export var method := Method.GET
## Request priority. Lower values are first in the client queue.
@export var priority := 0

var tmp := "hello"
