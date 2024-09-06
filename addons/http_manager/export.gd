extends EditorExportPlugin


func _get_name() -> String:
	return "ExportPluginHTTPManager"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	if platform is EditorExportPlatformPC:
		return true
	return false

func _get_export_options(_platform: EditorExportPlatform) -> Array[Dictionary]:
	return [{
		option = {
			name = &"http_server",
			type = TYPE_BOOL,
		},
		default_value = false,
	}]


func _get_export_features(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	if platform is EditorExportPlatformPC and get_option(&"http_server"):
		return ["http_server"]
	return []
