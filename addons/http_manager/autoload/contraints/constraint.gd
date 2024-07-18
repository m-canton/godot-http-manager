class_name HTTPManagerConstraint extends Resource


## HTTPManager Constraint for clients.
## 
## Do not use this class. Use any extended class to constrain a client.
## See [HTTPManagerClient.constraints].

## Indicates if HTTPManager must call process method.
var processing := false

## Indicates if it can request to this route.
func check(_route: HTTPManagerRoute) -> bool:
	return false

## Handles a route
func handle(_route: HTTPManagerRoute) -> void:
	pass

## Called by HTTPManager if [member processing] is true. Changes
## [member processing] since [method handle] and [method process] methods.
## It is used to handle constraint times.[br]
## Returns true if it must call [method HTTPManager.next].
func process(_delta: float) -> bool:
	return false
