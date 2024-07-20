extends HBoxContainer


@onready var button: Button = $Button


func _ready() -> void:
	button.pressed.connect(queue_free)
