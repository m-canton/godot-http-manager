class_name OAuth2PKCE extends RefCounted

## OAuth PKCE class.
## 
## Utils for OAuth PKCE. See [OAuth2].
## 
## [codeblock]
## var pkce := OAuth2PKCE.new()
## pkce.length = 128
## pkce.method = OAuth2PKCE.Method.PLAIN
## 
## print({
##     code_verifier = pkce.get_code_verifier(),
##     code_challenge = pkce.get_code_challenge(),
## })
## 
## pkce.random(43, OAuth2PKCE.Method.S256)
## 
## print({
##     code_verifier = pkce.get_code_verifier(),
##     code_challenge = pkce.get_code_challenge(),
## })
## [/codeblock]
## 
## [codeblock]
## print(OAuth2PKCE.generate_codes(128, OAuth2PKCE.Method.PLAIN))
## [/codeblock]
## 
## @tutorial(RFC 7636): https://datatracker.ietf.org/doc/html/rfc7636

## Methods.
enum Method {
	NONE, ## No method.
	PLAIN, ## Plain.
	S256, ## S256.
}

## Transformation method.
var method := Method.S256
## Code verifier length. Value between 43 and 128.
var length := 43
## Code verifier. See [method random].
var _code_verifier := ""

## Sets a random code verifier. You can change [member length] and
## [member method]. See [method get_code_verifier] and 
## [method get_code_challenge] to get the strings.[br]
## [b]Valid characters:[/b] 45: -, 46: ., 48-57: 0-9, 65-90: A-Z, 95: _, 97-122: a-z, 126: ~
func random(new_length := 0, new_method := Method.NONE) -> void:
	length = clamp(length if new_length == 0 else new_length, 43, 128)
	if new_method != Method.NONE: method = new_method
	
	_code_verifier = ""
	
	var i := 0
	while i < length:
		var ci := randi_range(0, 65)
		if ci < 2:
			ci += 45
		elif ci < 12:
			ci += 46
		elif ci < 38:
			ci += 53
		elif ci == 38:
			ci = 95
		elif ci < 65:
			ci += 58
		else:
			ci = 126
		_code_verifier += char(ci)
		i += 1

## Returns code verifier. Use [method random] to change code verifier.
func get_code_verifier() -> String:
	if _code_verifier.is_empty():
		random()
	return _code_verifier

## Returns code challenge.
func get_code_challenge() -> String:
	if _code_verifier.is_empty():
		random()
	if method == Method.S256:
		return Marshalls.utf8_to_base64(_code_verifier.sha256_text().uri_encode())
	return _code_verifier

## Returns a dictionary with random [code]"code_verifier"[/code] and
## [code]"code_challenge"[/code].
static func generate_codes(length := 43, method := Method.S256) -> Dictionary:
	var pkce := OAuth2PKCE.new()
	return {
		code_verifier = pkce.get_code_verifier(),
		code_challenge = pkce.get_code_challenge(),
	}

## Converts [enum Method] to [String]. Use in requests.
static func method_to_string(method: Method) -> String:
	if method == Method.S256:
		return "S256"
	
	if method == Method.PLAIN:
		return "plain"
	
	return ""
