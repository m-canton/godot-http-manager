# HTTP Manager Plugin for Godot

## Introduction

This plugin adds a `HTTPManager` autoload to make multiple requests using routes defined with resources.

Routes have attached a client, resource that defines the host. You can add constraints to the client like requests per second.

Example:

```gdscript
extends Node

const ROUTE_WEBSITE_POSTS := preload("res://website/posts.tres")

func _request_posts() -> void:
    HTTPManagerRequest.create_from_route(ROUTE_WEBSITE_POSTS).start({
        
    }).completed.connect(_on_request_completed)

func _on_request_completed(response: HTTPManagerResponse) -> void:
    var data = response.parse()
```

## Requirements

- Godot version: 4.2.x, 4.3.x
