class_name HTTPManagerValidatedData extends RefCounted


var _data := {}
var errors := {}


func _init(data: Dictionary, rules: Dictionary) -> void:
	_data = data


## Returns validated data as [Dictionary]. Check if there are errors with
## [method has_error].
func all() -> Dictionary:
	return _data

## Returns validated data excluding specified [param keys].
func except(keys: PackedStringArray, exclude_null := true) -> Dictionary:
	var data := {}
	for key in _data:
		if not key in keys:
			var value = _data[key]
			if exclude_null and value == null:
				continue
			data[key] = value
	return data

## Return [code]true[/code] if it has some error.
func has_error() -> bool:
	return not errors.is_empty()

## Returns validated data containing only specified [param keys].
func only(keys: PackedStringArray, exclude_null := true) -> Dictionary:
	var data := {}
	for key in keys:
		var value = _data.get(key)
		if exclude_null and value == null:
			continue
		data[key] = value
	return data
