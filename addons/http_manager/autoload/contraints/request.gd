class_name HTTPManagerConstraintRequest extends HTTPManagerConstraint


## Requests per selected unit.
@export_range(0, 10, 1, "or_greater") var requests := 1
@export_range(0, 360, 1, "or_greater", "hide_slider") var seconds := 1.0
## Methods to restrict. If it is null, all the methods are affected.
@export var methods: Array[HTTPManagerRoute.Method] = []

var _countdowns: PackedFloat64Array = []


func check(route: HTTPManagerRoute) -> bool:
	if not methods.is_empty() and not route.method in methods:
		return true
	return _countdowns.size() < requests


func handle(route: HTTPManagerRoute) -> void:
	if methods.is_empty() or route.method in methods:
		_countdowns.append(seconds)
		processing = true


func process(delta: float) -> bool:
	var i := 0
	var s0 := _countdowns.size()
	var s := s0
	while i < s:
		_countdowns[i] -= delta
		if _countdowns[i] <= 0.0:
			_countdowns.remove_at(i)
			s -= 1
			continue
		i += 1
	
	if s == 0:
		processing = false
	
	return s < s0
