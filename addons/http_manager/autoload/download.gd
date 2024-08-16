class_name HTTPManagerDownload extends RefCounted


const CACHE_FILE_PATH := "user://addons/http_manager/cache.ini"


## Request URL.
var url := ""
## Download path.
var path := ""
## Indicates if it stores the data in cache.
var cache := false
## It does nothing for now.
var priority := 0


func start() -> Error:
	if not HTTPManagerRequest.http_manager:
		push_error("HTTPManager is not started.")
		return FAILED
	
	HTTPManagerRequest.http_manager.download(self)
	
	return OK
