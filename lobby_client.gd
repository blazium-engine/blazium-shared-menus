extends ScriptedLobbyClient

@export var reconnects := 0
@export var discord: CustomDiscordEmbeddedAppClient
@export var login: CustomLoginClient
@export var pogr: POGRCustomClient

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


func _received_jwt(_jwt: String, _type: String, access_token: String):
	var result = await discord.authenticate(access_token).finished
	print(result.data)


func _ready() -> void:
	config = ConfigFile.new()
	config.load("user://blazium.cfg")
	connected_to_server.connect(_connected_to_server)
	disconnected_from_server.connect(_disconnected_from_server)
	log_updated.connect(_log_updated)
	if discord.is_discord_environment():
		var auth_id = await login.auth_id_flow("discord")
		var discord_access_code = await discord.discord_access_code_flow()
		var access_token: LoginAccessTokenResult = await login.request_access_token("discord", auth_id, discord_access_code).finished
		if access_token.has_error():
			push_error(access_token.error)
			#return
	else:
		reconnection_token = config.get_value("LobbyClient", "reconnection_token", "")
	var local_server = ProjectSettings.get_setting("blazium/game/lobby_server_local", false)
	if local_server:
		server_url = "ws://localhost:8080/connect"

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

	var err = config.save("user://blazium.cfg")
	if err != OK:
		push_error(error_string(err))
	# Rejoin old lobby automatically
	if lobby.id != "":
		join_lobby(lobby.id)


func _disconnected_from_server(reason: String):
	if reason == "Reconnect Close":
		reconnection_token = ""
	print("Disconnected. ", reason)
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

func call_settings_menu_event():
	pogr.add_event("settings")

func call_about_menu_event():
	pogr.add_event("about")
