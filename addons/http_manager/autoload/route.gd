class_name HTTPManagerRoute extends Resource

## HTTPManager route resource.
## 
## Defines a client route to use with HTTPManagerRequest.

const MIMETYPE_JSON := "application/json"
const MIMETYPE_URL_ENCODED := "application/x-www-form-urlencoded"

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
@export_multiline var request_data := ""
@export var priority := 0
