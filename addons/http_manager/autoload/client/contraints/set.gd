class_name HTTPManagerConstraintSet extends Resource

## HTTPManager Constraint Set.
## 
## A collection of contraints to constrain a client.
## See [member SceneManagerClient.constraint_sets].[br]
## [b]Note:[/b] Do not use the same constraint set in different clients because
## they are cached. Use inspector to create them since client exported variable.

## Client contraints. Do not use the same resource in different sets because
## they are cached. It is better to create since inspector dock.
@export var constraints: Array[HTTPManagerConstraint] = []
