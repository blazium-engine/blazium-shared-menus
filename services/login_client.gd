extends LoginClient

@export var discord: DiscordEmbeddedAppClient
var config: ConfigFile

func _init() -> void:
	var result :LoginConnectResult= await connect_to_server().finished
	if result.has_error():
		push_error(result.error)
		return
	disconnected_from_server.connect(_disconnected_from_server)
	received_jwt.connect(_received_jwt)
	log_updated.connect(_log_updated)

func _log_updated(command: String, message: String):
	print("[LoginClient]: ", command, ": ", message)

func _received_jwt(jwt: String, type: String, access_token: String):
	print("Got jwt and access_token", jwt, " ", type, " ", access_token)

func _disconnected_from_server(reason: String):
	print(reason)

func external_login(platform_type: String):
	var result = await connect_to_server().finished
	if result.has_error():
		print(result.error)
	var login_result :LoginURLResult = await request_login_info(platform_type).finished
	if login_result.has_error():
		print("error ", login_result.error)
	OS.shell_open(login_result.login_url)

func auth_id_flow(platform_type: String):
	var auth_id :LoginIDResult = await request_auth_id(platform_type).finished
	if auth_id.has_error():
		push_error(auth_id.error)
		return
	return auth_id.login_id
	
