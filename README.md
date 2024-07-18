# HTTP Manager Plugin for Godot

A plugin to create route resources for Rest APIs. So you use this code to make a request:

```gdscript
extends Node

const ROUTE_WEBSITE_POSTS := preload("res://website/posts.tres")

func _request_posts() -> void:
    var request := HTTPManagerRequest.new(ROUTE_WEBSITE_POSTS)
    request.completed.connect(_on_request_completed)
    request.start({
        q = "word to search"
    })

func _on_request_completed(response: HTTPManagerResponse) -> void:
    var data = response.parse()
```

## Requirements

- Godot version: 4.3.x
