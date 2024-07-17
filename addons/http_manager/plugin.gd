@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("HTTPManager", "res://addons/http_manager/autoload/http_manager.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("HTTPManager")
