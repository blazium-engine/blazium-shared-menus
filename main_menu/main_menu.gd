@tool
extends BlaziumPanel

@export var title_label: Label
@export var name_label: Label
@export var multiplayer_button: Button
@export var quit_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var click_sound: AudioStreamPlayer

var loading_scene: PackedScene = load("res://addons/blazium_shared_menus/loading_screen/loading_screen.tscn")
var lobby_browser_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_browser/lobby_browser.tscn")
var lobby_viewer_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/lobby_viewer.tscn")
var lobby_creator_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_creator/lobby_creator.tscn")
var settings_scene: PackedScene = load("res://addons/blazium_shared_menus/settings/settings.tscn")
var about_scene: PackedScene = load("res://addons/blazium_shared_menus/about/about.tscn")

var exit_popup: CustomDialog

var os_manages_quit: bool = OS.get_name() in ["Android", "iOS", "Web"]


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	resized.connect(_on_resized)
	_on_resized()
	title_label.text = ProjectSettings.get("application/config/name")

	GlobalLobbyClient.connected_to_server.connect(_connected_to_server)
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	GlobalLobbyClient.lobby_joined.connect(_lobby_joined)
	if GlobalLobbyClient.lobby.id != "":
		GlobalLobbyClient.lobby_joined.emit(GlobalLobbyClient.lobby, GlobalLobbyClient.peers)
	if GlobalLobbyClient.connected:
		_connected_to_server(GlobalLobbyClient.peer, "")
	else:
		_disconnected_from_server("")
	quit_button.visible = not os_manages_quit


func _lobby_joined(_lobby: LobbyInfo, _peers: Array[LobbyPeer]):
	# If in a lobby
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_viewer_scene)


func _connected_to_server(peer: LobbyPeer, _reconnection_token: String):
	var peer_name: String = peer.user_data.get("name", "")
	# If no name
	if peer_name == "":
		peer_name = tr("player_name") + str(randi() % 1000)
		var avatar := SettingsAutoload.config.get_value("Cosmetics", "avatar", randi() % 28)
		await GlobalLobbyClient.add_peer_user_data({"name": peer_name, "avatar": avatar}).finished
	name_label.show()
	name_label.text = tr("player_greet").format({player = peer_name})
	_set_fallback_focus(multiplayer_button)
	multiplayer_button.grab_focus()
	try_join_from_url()


func get_query_param(query_string: String, key: String) -> String:
	if query_string.begins_with("?"):
		query_string = query_string.substr(1)

	# Split into key=value pairs
	var pairs = query_string.split("&")

	for pair in pairs:
		var kv = pair.split("=")
		if kv.size() == 2 and kv[0] == key:
			return kv[1]

	# Return empty string or null if key not found
	return ""


func try_join_from_url() -> void:
	# If on web and not on discord
	if OS.get_name() != "Web" || GlobalLobbyClient.is_discord_environment():
		return
	# get code from url
	var lobby_code: String = JavaScriptBridge.eval("window.location.search", true)
	if lobby_code.is_empty() or !lobby_code.contains("code="):
		return
	GlobalLobbyClient.join_lobby(get_query_param(lobby_code, "code"))
	# clear code from url
	JavaScriptBridge.eval("history.replaceState(null, '', '/')", true)


func _on_button_join_public_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_browser_scene)


func _on_button_lobby_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_creator_scene)


func _on_start_pressed() -> void:
	click_sound.play()
	await GlobalLobbyClient.lobby_call("start_game").finished


func _on_resized() -> void:
	var show_spacers = GlobalLobbyClient.ui_breakpoint()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers


func _on_button_settings_pressed() -> void:
	GlobalLobbyClient.call_event("settings")
	click_sound.play()
	await click_sound.finished
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(settings_scene)


func _on_quit_button_pressed() -> void:
	GlobalLobbyClient.call_event("quit")
	click_sound.play()
	exit_popup.show()
	exit_popup.confirm_button.grab_focus();


func _shortcut_input(_event):
	if Input.is_action_just_pressed("ui_cancel") and not os_manages_quit:
		if exit_popup.visible:
			exit_popup.visible = false
			_on_exit_popup_cancelled()
		else:
			_on_quit_button_pressed()


func _on_exit_popup_confirmed() -> void:
	click_sound.play()
	await click_sound.finished
	get_tree().quit()


func _on_exit_popup_cancelled() -> void:
	click_sound.play()
	quit_button.grab_focus()


func _play_click_sound() -> void:
	click_sound.play()


func _on_create_lobby_pressed() -> void:
	GlobalLobbyClient.call_event("create_lobby")
	click_sound.play()
	await click_sound.finished
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_creator_scene)


func _on_about_button_pressed() -> void:
	GlobalLobbyClient.call_event("about")
	click_sound.play()
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(about_scene)


func _init():
	exit_popup = CustomDialog.new("menu_prompt_exit")
	exit_popup.name = "ExitPopup"
	exit_popup.cancelled.connect(_on_exit_popup_cancelled)
	exit_popup.confirmed.connect(_on_exit_popup_confirmed)
	exit_popup.hide()
	add_child(exit_popup, false, Node.INTERNAL_MODE_BACK)


func _disconnected_from_server(reason: String):
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(loading_scene)


func _on_competitive_button_pressed() -> void:
	GlobalLobbyClient.call_event("competitive_start")
	click_sound.play()
	await click_sound.finished
	var res: ViewLobbyResult = await GlobalLobbyClient.quick_join(tr("lobby_title_game")  + str(randi() % 1000), {"game_mode": "competitive_abunch_hanging"}, ProjectSettings.get_setting("blazium/game/max_players_default")).finished
	var result: ScriptedLobbyResult = await GlobalLobbyClient.lobby_call("start_game").finished
	if res.has_error():
		push_error(res.error)
