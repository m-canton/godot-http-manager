# HTTP Manager Plugin for Godot

DO NOT USE THIS PLUGIN YET! CODE IS NOT COMPLETED

## Introduction

A plugin to create route resources for Rest APIs. So you use this code to make a request:

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

- Godot version: 4.3.x
