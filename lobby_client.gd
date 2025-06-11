extends ScriptedLobbyClient

@export var discord: CustomDiscordEmbeddedAppClient
@export var login: CustomLoginClient
@export var pogr: CustomPOGRClient
@export var steam: CustomSteamClient

var config: ConfigFile
var vertical = false
var disconnected
var jwt:String


func is_portrait() -> bool:
	var size = get_viewport().size
	return size.y > size.x


func is_landscape() -> bool:
	var size = get_viewport().size
	return size.y < size.x


func breakpoint_1024() -> bool:
	var size = get_viewport().size
	return size.x < 1024


func breakpoint_768() -> bool:
	var size = get_viewport().size
	return size.x < 768


func breakpoint_400() -> bool:
	var size = get_viewport().size
	return size.x < 400


func _size_changed():
	var window_size := Vector2(get_viewport().get_window().size)
	var scale_factor: float = window_size.y / window_size.x
	if scale_factor < 0.0:
		scale_factor = 1.0
	vertical = false
	if scale_factor > 1.05:
		vertical = true
	var min_dimension :float= min(window_size.x, window_size.y)

	# Custom scale based on window size
	var scale := min_dimension / 700.0
	var font_scale = scale / 4
	var font_size = 24
	# Apply settings
	#ProjectSettings.set_setting("gui/theme/font_size", font_size + font_scale * font_size)
	#ProjectSettings.set_setting("gui/theme/default_theme_scale", scale)


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
			config.set_value("LoginClient", "jwt", "")
			config.save("user://blazium.cfg")
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
	_size_changed()
	get_tree().root.size_changed.connect(_size_changed)
	var local_server = ProjectSettings.get_setting("blazium/game/lobby_server_local", false)
	if local_server:
		server_url = "ws://localhost:8080/connect"
	config = ConfigFile.new()
	config.load("user://blazium.cfg")
	GlobalLobbyClient.update_theme(config.get_value("Settings", "light_mode", false))
	connected_to_server.connect(_connected_to_server)
	disconnected_from_server.connect(_disconnected_from_server)
	log_updated.connect(_log_updated)
	await try_login()
	if jwt:
		reconnection_token = jwt
	else:
		reconnection_token = config.get_value("LobbyClient", "reconnection_token", "")
	connect_to_server()


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
	disconnected = false
	config.set_value("LobbyClient", "reconnection_token", new_reconnection_token)
	config.save("user://blazium.cfg")

	var err = config.save("user://blazium.cfg")
	if err != OK:
		push_error(error_string(err))
	# Rejoin old lobby automatically
	if lobby.id != "":
		join_lobby(lobby.id)


func _disconnected_from_server(reason: String):
	disconnected = true
	if reason == "Reconnect Close":
		reconnection_token = ""
	else:
		reconnection_token = jwt


func update_theme(is_light_theme: bool):
	if is_light_theme:
		ProjectSettings.set_setting("gui/theme/base_color", Color(0.63, 0.63, 0.63))
		ProjectSettings.set_setting("gui/theme/accent_color", Color(0.185, 0.21275, 0.74))
	else:
		ProjectSettings.set_setting("gui/theme/base_color", Color(0.0793, 0.10296, 0.13))
		ProjectSettings.set_setting("gui/theme/accent_color", Color(0.2075, 0.581, 0.83))


func call_event(event_name: String):
	pogr.add_event(event_name)


func is_discord_environment() -> bool:
	return discord.is_discord_environment()


func open_url(url: String):
	if is_discord_environment():
		discord.open_external_link(url)
	else:
		OS.shell_open(url)
