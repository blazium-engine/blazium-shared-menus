@tool
extends BlaziumPanel

@export var peer_name_line_edit: LineEdit
@export var title_label: Label
@export var name_label: Label
@export var logs: Label
@export var menu: VBoxContainer
@export var set_name_menu: VBoxContainer
@export var set_name_button: Button
@export var multiplayer_button: Button
@export var quit_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var click_sound: AudioStreamPlayer

var lobby_browser_scene: PackedScene = preload("res://addons/blazium_shared_menus/lobby_browser/lobby_browser.tscn")
var lobby_viewer_scene: PackedScene = preload("res://addons/blazium_shared_menus/lobby_viewer/lobby_viewer.tscn")
var lobby_creator_scene: PackedScene = preload("res://addons/blazium_shared_menus/lobby_creator/lobby_creator.tscn")
var settings_scene: PackedScene = preload("res://addons/blazium_shared_menus/settings/settings.tscn")
var about_scene: PackedScene = preload("res://addons/blazium_shared_menus/about/about.tscn")

var config: ConfigFile
var exit_popup: CustomDialog
var reconnect_popup: CustomDialog
var wrong_id_popup: CustomDialog


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	title_label.text = ProjectSettings.get("application/config/name")
	# Load settings options
	config = ConfigFile.new()
	config.load("user://blazium.cfg")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), config.get_value("Settings", "mute", false))
	GlobalLobbyClient.update_theme(config.get_value("Settings", "light_mode", false))
	_connected_to_server(GlobalLobbyClient.peer, "")
	GlobalLobbyClient.connected_to_server.connect(_connected_to_server)
	GlobalLobbyClient.lobby_joined.connect(_lobby_joined)
	quit_button.visible = not (OS.get_name() in ["Android", "iOS", "Web"])
	

func _lobby_joined(_lobby: LobbyInfo, _peers: Array[LobbyPeer]):
	# If in a lobby
	if is_inside_tree():
		get_tree().change_scene_to_packed.call_deferred(lobby_viewer_scene)


func _connected_to_server(peer: LobbyPeer, _reconnection_token: String):
	var peer_name: String = peer.user_data.get("name", "")
	# If no name
	if peer_name == "":
		menu.hide()
		set_name_menu.show()
		peer_name_line_edit.edit()
	else: # has name already
		menu.show()
		name_label.show()
		name_label.text = "Hello, " + peer_name
		peer_name_line_edit.text = peer_name
		set_name_menu.hide()
		multiplayer_button.grab_focus()


func _on_button_join_public_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_browser_scene)


func _on_button_lobby_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_creator_scene)


func _on_set_name_pressed() -> void:
	click_sound.play()
	if peer_name_line_edit.text == "":
		peer_name_line_edit.text = "Player" + str(randi() % 1000)
	var result: LobbyResult = await GlobalLobbyClient.add_peer_user_data({"name": peer_name_line_edit.text, "avatar": randi() % 28}).finished

	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	if not result.has_error():
		menu.show()
		set_name_menu.hide()
		name_label.show()
		name_label.text = "Hello, " + GlobalLobbyClient.peer.user_data["name"]
		multiplayer_button.grab_focus()


func _on_line_edit_text_submitted(_new_text: String) -> void:
	click_sound.play()
	_on_set_name_pressed()
	multiplayer_button.grab_focus()


func _on_resized() -> void:
	var show_spacers = size.x > 600
	left_spacer.visible = show_spacers
	right_spacer.visible = show_spacers


func _on_button_settings_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		get_tree().change_scene_to_packed(settings_scene)


func _on_quit_button_pressed() -> void:
	click_sound.play()
	exit_popup.show()
	exit_popup.confirm_button.grab_focus();


func _shortcut_input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		print("pressed")
		if exit_popup.visible:
			exit_popup.visible = false
			_on_exit_popup_cancelled()
		else:
			_on_quit_button_pressed()

func _on_reconnect_popup_confirmed() -> void:
	GlobalLobbyClient.connect_to_server()

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
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_creator_scene)


func _on_button_quickstart_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	var res: ViewLobbyResult = await GlobalLobbyClient.quick_join("Game" + str(randi() % 1000), {"max_points": 30}, ProjectSettings.get_setting("blazium/game/max_players_default")).finished
	if res.has_error():
		push_error(res.error)
	elif is_inside_tree():
		get_tree().change_scene_to_packed(lobby_viewer_scene)


func _on_about_button_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_packed(about_scene)


func _init():
	var quit_text = "Quit"
	if OS.get_name() in ["Android", "iOS", "Web"]:
		quit_text = ""
	reconnect_popup = CustomDialog.new("Connection lost!", "Reconnect", quit_text)
	reconnect_popup.name = "ReconnectPopup"
	reconnect_popup.cancelled.connect(_on_exit_popup_confirmed)
	reconnect_popup.confirmed.connect(_on_reconnect_popup_confirmed)
	reconnect_popup.hide()
	add_child(reconnect_popup, false, Node.INTERNAL_MODE_BACK)
	GlobalLobbyClient.disconnected_from_server.connect(func (reason: String): if GlobalLobbyClient.reconnects > 3: reconnect_popup.show())
	if GlobalLobbyClient.reconnects > 3 and not GlobalLobbyClient.connected:
		reconnect_popup.show()
	
	exit_popup = CustomDialog.new("Are You Sure You Want To Exit?")
	exit_popup.name = "ExitPopup"
	exit_popup.cancelled.connect(_on_exit_popup_cancelled)
	exit_popup.confirmed.connect(_on_exit_popup_confirmed)
	exit_popup.hide()
	add_child(exit_popup, false, Node.INTERNAL_MODE_BACK)
	wrong_id_popup = CustomDialog.new("Wrong Game Code", "Continue", "")
	wrong_id_popup.confirm_button.user_icon = "keyboard_double_arrow_right"
	wrong_id_popup.confirm_button.theme_type_variation = "SelectedButton"
	wrong_id_popup.confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrong_id_popup.confirmed.connect(_play_click_sound)
	wrong_id_popup.hide()
	add_child(wrong_id_popup, false, Node.INTERNAL_MODE_BACK)
	resized.connect(_on_resized)
