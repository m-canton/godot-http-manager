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
## Endpoint or uri. It must start with [code]/[/code].
@export var endpoint := ""
## Default headers for this route.
@export var headers := PackedStringArray()
## Method for this route.
@export var method := Method.GET
## Request priority. Lower values are first in the client queue.
@export var priority := 0
