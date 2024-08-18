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
	PLAIN, ## Plain.
	S256, ## S256.
}

## Method
var method := Method.S256
## Code verifier length. Value between 43 and 128.
var length := 43
## Code verifier.
var code_verifier := ""
## Code challenge.
var code_challenge := ""

## Sets a random code verifier. You can change [member length] and
## [member method]. See [method get_code_verifier] and 
## [method get_code_challenge] to get the strings.[br]
## [b]Valid characters:[/b] 45: -, 46: ., 48-57: 0-9, 65-90: A-Z, 95: _, 97-122: a-z, 126: ~
func random(new_length := 0) -> void:
	length = clamp(length if new_length == 0 else new_length, 43, 128)
	code_verifier = OAuth2.generate_state(length)
	code_challenge = Marshalls.utf8_to_base64(code_verifier.sha256_text()) if method == Method.S256 else code_verifier

func get_method_string() -> String:
	if method == Method.S256:
		return "S256"
	
	if method == Method.PLAIN:
		return "plain"
	
	return ""
