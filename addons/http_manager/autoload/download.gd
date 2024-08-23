class_name HTTPManagerDownload extends RefCounted

## HTTP Manager Download
## 
## This [RefCounted] is used to create a download with its URL.
## 
## @experimental


## Request URL.
var url := ""
## Download path.
var path := ""
## Indicates if it stores the data in cache.
var cache := false
## It does nothing for now.
var priority := 0


## It starts the download.
## @experimental
func start() -> Error:
	if not HTTPManagerRequest.http_manager:
		push_error("HTTPManager is not started.")
		return FAILED
	
	HTTPManagerRequest.http_manager.download(self)
	
	return OK


static func create_from_url(u: String) -> HTTPManagerDownload:
	var d := HTTPManagerDownload.new()
	d.url = u
	return d
