class_name OAuth2 extends Node


## OAuth 2.0 Local Redirect.
## 
## It starts local TCP server to handle a OAuth 2.0 redirect URI. Intended for personal
## tools for all those who like Godot.[br]
## It can generate random state and PKCE code verifier.
## 
## @tutorial(OAuth 2.0): https://datatracker.ietf.org/doc/html/rfc6749
## @tutorial(RFC 7636): https://datatracker.ietf.org/doc/html/rfc7636

## Setting name for default local server bind address.
const SETTING_NAME_BIND_ADDRESS := "addons/http_manager/auth/bind_address"
## Default local bind address.
const DEFAULT_BIND_ADDRESS := "127.0.0.1"
## Setting name for default local server port.
const SETTING_NAME_PORT := "addons/http_manager/auth/port"
## Default local server port.
const DEFAULT_PORT := 8120
## Default local server callback path.
const SETTING_NAME_CALLBACK_PATH := "addons/http_manager/auth/callback"
## Default local server callback path.
const DEFAULT_CALLBACK_PATH := "/auth/callback"

## URI unreserved characters.
const UNRESERVED_CHARACTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"

## Request reference.
var request: HTTPManagerRequest
## Redirect TCP server.
var _redirect_server: TCPServer
## Loads local HTML file to display in the redirect URI: <bind_address>:<port>.
## See [method set_redirect_html].
var _redirect_html := ""
## Server timeout.
var _timeout := 0.0
## Other query params from redirect URI.
var _token_request_body := {
	grant_type = "authorization_code",
}
## State.
var _state := ""
## Current time. See [member duration].
var _time := 0.0
## Parsed redirect URI.
var _parsed_redirect_uri: HTTPManagerClientParsedUrl
## Callable called when OAuth finishes.
var _on_complete_callable: Callable
## Error.
var _error := ""

## Calls [method Node.queue_free] on code received or timeout.
func _process(delta: float) -> void:
	_time += delta
	if _time >= _timeout:
		push_warning("OAuth 2.0 Timeout. No code received.")
		var response := HTTPManagerResponse.new()
		response.successful = false
		request.complete(response)
		queue_free()
	elif _redirect_server.is_connection_available():
		var connection := _redirect_server.take_connection()
		var crequest := connection.get_string(connection.get_available_bytes())
		
		connection.put_data("HTTP/1.1 200\r\n".to_ascii_buffer())
		if _redirect_html.is_empty():
			_redirect_html = HTMLDocument.create_default().text
		connection.put_data(_redirect_html.to_ascii_buffer())
		
		if _handle_code_request(crequest):
			if _error != "":
				if not _on_complete_callable.is_null():
					var response := HTTPManagerResponse.new()
					response.body = _error.to_ascii_buffer()
					_on_complete_callable.call(response)
			queue_free()

#region Chain Methods
## Enables PKCE and adds code_challenge as URL query param. [param method] must
## be [code]"plain"[/code] or [code]"S256"[/code]. Changes code_challenge,
## code_challenge_method and code_verifier param names using [param params].[br]
## [b]Note:[/b] Max length is 128.
func set_pkce(length := 43, method := "S256") -> OAuth2:
	length = clamp(length, 43, 128)
	var code_verifier := OAuth2.generate_state(length)
	var code_challenge := code_verifier if method == "plain" else Marshalls.utf8_to_base64(code_verifier.sha256_text())
	if method != "plain": method = "S256" 
	_token_request_body["code_verifier"] = code_verifier
	request.parsed_url.query_param_join("code_challenge", code_challenge)
	request.parsed_url.query_param_join("code_challenge_method", method)
	return self

## Sets random state. Minimum length is 32. It is added as URL query param.
func set_state(length := 100) -> OAuth2:
	length = max(length, 32)
	_state = OAuth2.generate_state(length)
	request.parsed_url.query_param_join("state", _state)
	return self
#endregion

## Starts the OAuth 2.0. Frees other [OAuth2].
func _start(options := {}) -> Error:
	if not HTTPManagerRequest.http_manager:
		push_error("HTTPManager is not started.")
		queue_free()
		return FAILED
	
	if not request.valid:
		return FAILED
	
	_on_complete_callable = options.get("on_complete", Callable())
	
	# One OAuth 2.0
	for c in HTTPManagerRequest.http_manager.get_children():
		if c is OAuth2:
			c.queue_free()
	
	var client_id := request.parsed_url.find_query_param("client_id")
	if client_id.is_empty():
		push_error("OAuth 2.0 needs client ID.")
		return FAILED
	
	_token_request_body["client_id"] = client_id
	var redirect_uri := request.parsed_url.find_query_param("redirect_uri")
	_token_request_body["redirect_uri"] = redirect_uri
	
	_parsed_redirect_uri = HTTPManagerClient.parse_url(redirect_uri)
	if not _parsed_redirect_uri:
		push_error("Redirect URI is not valid.")
		return FAILED
	
	var error := FAILED
	if _timeout > 0.0:
		var domain := _parsed_redirect_uri.domain
		if domain == "localhost": domain = "127.0.0.1"
		if not domain.is_valid_ip_address():
			push_error("Redirect server requires a domain as IP.")
			return error
		
		_redirect_server = TCPServer.new()
		error = _redirect_server.listen(_parsed_redirect_uri.port, domain)
		if error:
			push_error("It cannot listen the port.")
			return error
	
	error = request.shell()
	if error:
		return error
	
	if _redirect_server:
		HTTPManagerRequest.http_manager.add_child(self)
	
	return OK

## Starts the server and request with options: timeout, html,
## on_complete.[br]
## Enables local server when timeout is positive.
func start(options := {}) -> Error:
	_timeout = options.get("timeout", 60.0)
	if _timeout < 0.0:
		push_error("'timeout' must be positive.")
		return FAILED
	
	var html = options.get("html")
	_redirect_html = html.text if html is HTMLDocument else html if html is String else _redirect_html
	
	return _start(options)

## Handles request string received on local server. Returns [code]true[/code]
## if this is the expected code request and starts requesting access token.
func _handle_code_request(request_string: String) -> bool:
	# Check if it is valid request.
	var r := HTTPManagerRequest.parse_string(request_string)
	if not r: return false
	
	# Check if it is the correct URI.
	for p in ["scheme", "domain", "port", "path"]:
		if _parsed_redirect_uri.get(p) != r.parsed_url.get(p):
			return false
	
	# Check state.
	var state: String = r.parsed_url.find_query_param("state")
	if _state != state:
		return false
	
	# Check if it has error.
	_error = r.parsed_url.find_query_param("error")
	if _error:
		return true
	
	# Check if code is valid.
	var _code: String = r.parsed_url.find_query_param("code")
	if _code.is_empty():
		push_error("Authorization code is empty.")
		_error = "Authorization code is empty."
		return true
	
	_token_request_body["code"] = _code
	var client_secret := request.route.auth_route.client.data.get_client_secret()
	if client_secret != "": _token_request_body["client_secret"] = client_secret
	
	request.route.auth_route.create_request() \
			.set_body(_token_request_body, MIME.Type.URL_ENCODED) \
			.start(request.route.client.data.save_oauth2_token_from_response)
	return true

## Returns a random state string.
static func generate_state(length := 100) -> String:
	var s := ""
	var i := 0
	while i < length:
		s += UNRESERVED_CHARACTERS[randi_range(0, 65)]
		i += 1
	return s

## Returns local server redirect URI. Change it in settings.
static func get_local_server_redirect_uri(subpath := "") -> String:
	var parsed_url := HTTPManagerClientParsedUrl.new()
	parsed_url.port = ProjectSettings.get_setting(SETTING_NAME_PORT, DEFAULT_PORT)
	parsed_url.scheme = "https" if parsed_url.port == 443 else "http"
	parsed_url.domain = ProjectSettings.get_setting(SETTING_NAME_BIND_ADDRESS, DEFAULT_BIND_ADDRESS)
	parsed_url.path = ProjectSettings.get_setting(SETTING_NAME_CALLBACK_PATH, DEFAULT_CALLBACK_PATH)
	if subpath != "": parsed_url.path = parsed_url.path.path_join(subpath)
	return parsed_url.get_url()

## Requests if access token is valid. In other case, use refresh token to
## update it and after requests [param r].
static func check(r: HTTPManagerRequest) -> Error:
	var data := r.route.auth_route.client.data
	if data.check_token():
		var token_type: String = data.get_token_type()
		if token_type == "Bearer":
			var access_token = data.get_access_token()
			if access_token.is_empty():
				push_error("No access token.")
				return FAILED
			return HTTPManagerRequest.http_manager.start_request(r.set_bearer_auth(access_token))
		else:
			push_error("It cannot request. Unknown token type: ", token_type)
			return FAILED
	
	var client_id: String = data.get_client_id()
	if client_id.is_empty():
		push_error("It cannot request token because 'client_id' is empty.")
		return FAILED
	
	var refresh_token: String = data.get_refresh_token()
	if refresh_token.is_empty():
		push_error("It cannot request token because 'refresh_token' is empty.")
		return FAILED
	
	# Body dict.
	var body_dict := {
		client_id = client_id,
		refresh_token = refresh_token,
		grant_type = "refresh_token",
	}
	
	# Client secret.
	var client_secret := data.get_client_secret()
	if client_secret != "": body_dict["client_secret"] = client_secret
	
	var refresh_token_request := r.route.auth_route.auth_route.create_request().set_body(body_dict, MIME.Type.URL_ENCODED)
	refresh_token_request.set_meta(&"pending_request", r)
	return refresh_token_request.start(r.complete_with_auth2_token)

## Saves the token in a config file. Response must have a JSON body with
## the following keys: access_token, refresh_token, expires_in, token_type.
## Other keys are saved too.
static func save_token(file: ConfigFile, response: HTTPManagerResponse) -> Error:
	if not response.successful:
		push_error("Auth Token Request Error. Code: ", response.code)
		return FAILED
	
	var token_dict = response.parse()
	if not token_dict is Dictionary:
		push_error("Auth Token Response is not JSON: ", token_dict)
		return FAILED
	
	if token_dict.has("error"):
		return FAILED
	
	if not token_dict.has("access_token"):
		push_error("No access token.")
		return FAILED
	
	for key in token_dict:
		var value = token_dict[key]
		if key == "expires_in":
			value = int(value)
			var t := int(Time.get_unix_time_from_system())
			if value < t:
				value += t
		file.set_value("token", key, value)
	
	return OK
