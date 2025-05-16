extends ScriptedLobbyClient

@export var reconnects := 0
@export var discord: CustomDiscordEmbeddedAppClient
@export var login: CustomLoginClient
@export var pogr: CustomPOGRClient
@export var steam: CustomSteamClient

var config: ConfigFile
var show_debug := false


func _size_changed():
	var scale_factor: float = float(get_viewport().get_window().size.y) / get_viewport().get_window().size.x
	if scale_factor > 2.0:
		scale_factor = 3.0
	elif scale_factor > 1.6:
		scale_factor = 2.4
	elif scale_factor > 1.3:
		scale_factor = 2.0
	elif scale_factor > 0.7:
		scale_factor = 1.5
	else:
		scale_factor = 1.0
	get_tree().root.content_scale_factor = scale_factor

var jwt:String

func try_login() -> bool:
	if !login.connected:
		var result :LoginConnectResult= await login.connect_to_server().finished
		if result.has_error():
			login.disconnect_from_server()
			push_error(result.error)
			return false
	jwt = config.get_value("LoginClient", "jwt", "")
	if !jwt.is_empty():
		var jwt_verify_result:LoginVerifyTokenResult= await login.verify_jwt_token(jwt).finished
		if jwt_verify_result.has_error():
			push_error(jwt_verify_result.error)
			jwt = ""
		else:
			print("[ScriptedLobby]: Authentication already done, reusing JWT.")
			login.disconnect_from_server()
			return true
	if discord.is_discord_environment():
		var auth_id = await login.auth_id_flow("discord")
		var discord_access_code = await discord.discord_access_code_flow()
		var auth_code: LoginAuthResult = await login.request_auth("discord", auth_id, discord_access_code).finished
		if auth_code.has_error():
			login.disconnect_from_server()
			push_error(auth_code.error)
			return false
	elif steam.login_steam():
		var steam_ticket :String= await steam.ticket_received
		if steam_ticket.is_empty():
			push_error("Cannot login")
			login.disconnect_from_server()
			return false
		var auth_id = await login.auth_id_flow("steam")
		var auth_code: LoginAuthResult = await login.request_steam_auth(auth_id, steam_ticket).finished
		if auth_code.has_error():
			login.disconnect_from_server()
			push_error(auth_code.error)
			return false
	else:
		jwt = ""
		return false
		# Web external login
		login.external_login("discord")
	jwt = login.jwt
	config.set_value("LoginClient", "jwt", login.jwt)
	config.save("user://blazium.cfg")
	login.disconnect_from_server()
	return true

func _ready() -> void:
	var local_server = ProjectSettings.get_setting("blazium/game/lobby_server_local", false)
	if local_server:
		server_url = "ws://localhost:8080/connect"
	config = ConfigFile.new()
	config.load("user://blazium.cfg")
	connected_to_server.connect(_connected_to_server)
	disconnected_from_server.connect(_disconnected_from_server)
	log_updated.connect(_log_updated)
	await try_login()
	if jwt:
		reconnection_token = jwt
	else:
		reconnection_token = config.get_value("LobbyClient", "reconnection_token", "")
	connect_to_server()
	_size_changed()
	get_tree().root.size_changed.connect(_size_changed)


func is_dealer():
	return lobby.data.get("dealer", "") == peer.id


func get_dealer() -> LobbyPeer:
	for peer_cur in peers:
		if lobby.data.get("dealer", "") == peer_cur.id:
			return peer_cur
	return null


func _log_updated(command: String, message: String):
	print("[ScriptedLobbyClient]: ", command, ": ", message)


func _connected_to_server(_peer: LobbyPeer, new_reconnection_token: String):
	reconnects = 0
	config.set_value("LobbyClient", "reconnection_token", new_reconnection_token)
	config.save("user://blazium.cfg")

	var err = config.save("user://blazium.cfg")
	if err != OK:
		push_error(error_string(err))
	# Rejoin old lobby automatically
	if lobby.id != "":
		join_lobby(lobby.id)


func _disconnected_from_server(reason: String):
	if reason == "Reconnect Close":
		reconnection_token = ""
	else:
		reconnection_token = jwt
	print("[ScriptedLobbyClient]: Disconnected. ", reason)
	if reconnects > 3:
		push_error("Cannot connect")
		return
	reconnects += 1
	if is_inside_tree():
		await get_tree().create_timer(1 * reconnects).timeout
	connect_to_server()


func update_theme(is_light_theme: bool):
	if is_light_theme:
		ProjectSettings.set_setting("gui/theme/base_color", Color(0.63, 0.63, 0.63))
		ProjectSettings.set_setting("gui/theme/accent_color", Color(0.185, 0.21275, 0.74))
	else:
		ProjectSettings.set_setting("gui/theme/base_color", Color(0.0793, 0.10296, 0.13))
		ProjectSettings.set_setting("gui/theme/accent_color", Color(0.2075, 0.581, 0.83))

func call_event(event_name: String):
	pogr.add_event(event_name)
