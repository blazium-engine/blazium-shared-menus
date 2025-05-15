class_name CustomLoginClient
extends LoginClient

@export var discord: DiscordEmbeddedAppClient
var jwt: String

func _init() -> void:
	received_jwt.connect(_received_jwt)
	log_updated.connect(_log_updated)

func _log_updated(command: String, message: String):
	print("[LoginClient]: ", command, ": ", message)

func _received_jwt(p_jwt: String, type: String, access_token: String):
	jwt = p_jwt

func external_login(platform_type: String):
	var result = await connect_to_server().finished
	if result.has_error():
		print("[LoginClient]: ", result.error)
	var login_result :LoginURLResult = await request_login_info(platform_type).finished
	if login_result.has_error():
		push_error("[LoginClient]: ", login_result.error)
	OS.shell_open(login_result.login_url)

func auth_id_flow(platform_type: String):
	var auth_id :LoginIDResult = await request_auth_id(platform_type).finished
	if auth_id.has_error():
		push_error(auth_id.error)
		return
	return auth_id.login_id
	
