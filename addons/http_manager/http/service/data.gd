class_name HTTPManagerServiceData extends Resource

## This is the dir name in user folder. [code].[/code] is replaced by
## [code]/[/code].
@export var name := ""
## Description.
@export_multiline var description := ""
@export var base_url := ""
@export var default_headers: PackedStringArray
@export var default_auths: Array[HTTPManagerAuth]
@export var gzip := false

@export_group("Query", "query_")
@export var query_array_type := ""
@export var query_bool_true := "1"
@export var query_bool_false := "0"

@export_group("Response", "response_")
@export var pagination: Resource
