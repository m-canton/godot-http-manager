class_name HTTPManagerRoute extends Resource

const MIMETYPE_JSON := "application/json"
const MIMETYPE_URL_ENCODED := "application/x-www-form-urlencoded"

@export var client: HTTPManagerClient
@export var endpoint := ""
@export var headers := PackedStringArray()
@export var method: HTTPClient.Method = HTTPClient.METHOD_GET
@export_multiline var request_data := ""
@export var priority := 0
