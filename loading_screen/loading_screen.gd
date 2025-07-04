@tool
extends BlaziumControl

@export var loading_label: Label
@export var click_sound: AudioStreamPlayer

var main_menu_scene:PackedScene = preload("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")
var reconnect_popup: CustomDialog
var os_manages_quit: bool = OS.get_name() in ["Android", "iOS", "Web"]

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var quit_text = "menu_quit"
	if os_manages_quit:
		quit_text = ""
	reconnect_popup = CustomDialog.new("loading_connection_lost", "loading_reconnect", quit_text)
	reconnect_popup.name = "ReconnectPopup"
	reconnect_popup.cancelled.connect(_on_exit_popup_confirmed)
	reconnect_popup.confirmed.connect(_on_reconnect_popup_confirmed)
	reconnect_popup.hide()
	add_child(reconnect_popup, false, Node.INTERNAL_MODE_BACK)
	if GlobalLobbyClient.disconnected:
		reconnect_popup.show()
	_play_loading_animation()
	if GlobalLobbyClient.connected:
		_connected_to_server(GlobalLobbyClient.peer, GlobalLobbyClient.reconnection_token)
	GlobalLobbyClient.connected_to_server.connect(_connected_to_server)
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)

func _disconnected_from_server(_reason: String):
	reconnect_popup.show()

func _play_loading_animation() -> void:
	var tween: = create_tween()
	tween.set_loops()

	# Bounce scale
	tween.tween_property(loading_label, "scale", Vector2(1.1, 0.8), 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(loading_label, "scale", Vector2(0.95, 2.7), 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(loading_label, "scale", Vector2(2.0, 1.5), 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _connected_to_server(peer: LobbyPeer, _reconnection_token: String):
	var peer_name = peer.user_data.get("name", "")
	# If no name
	if peer_name == "":
		peer_name = tr("player_name") + str(randi() % 1000)
		var avatar := SettingsAutoload.config.get_value("Cosmetics", "avatar", randi() % 28)
		await GlobalLobbyClient.add_peer_user_data({"name": peer_name, "avatar": avatar}).finished
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_reconnect_popup_confirmed() -> void:
	GlobalLobbyClient.connect_to_server()
	_restore_last_focus()

func _on_exit_popup_confirmed() -> void:
	click_sound.play()
	await click_sound.finished
	get_tree().quit()
