# HTTP Manager Plugin for Godot

## Introduction

This plugin adds a `HTTPManager` autoload to make multiple requests using routes defined with resources.

Routes have attached a client, resource that defines the host. You can add constraints to the client like requests per second.

**Example:**

```gdscript
extends Node

const ROUTE := preload("res://path/to/route.tres")

func _request_posts() -> void:
    var r := ROUTE.create_request()
    if HTTPManager.request(r) == OK:
         r.completed.connect(_on_request_completed)

func _on_request_completed(response: HTTPManagerResponse) -> void:
    var data = response.parse()
    if response.successful:
        print(data)
    else:
        push_error("Request error.")
```

**Await Example:**

```gdscript
extends Node

const ROUTE := preload("res://path/to/route.tres")

func _request_posts() -> void:
    var result = await HTTPManager.fetch(ROUTE.create_request())
    if result is Dictionary:
        print(result)
```

See [wiki](https://github.com/m-canton/godot-http-manager/wiki) to know how to use this plugin.

## Requirements

- Godot version: 4.2.x, 4.3.x
