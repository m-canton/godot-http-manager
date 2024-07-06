class_name HTTPManagerRequestData extends Node

signal request_completed(response: HTTPManagerResponse)

var url := ""
var headers := PackedStringArray()
var method: HTTPClient.Method = HTTPClient.METHOD_GET
var request_data := ""
var priority := 0
