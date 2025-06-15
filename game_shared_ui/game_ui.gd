class_name GameUI
extends BlaziumControl

@export var private_checkbutton: CheckBox

@export var player_list: HBoxContainer
@export var user_element_scene: PackedScene
@export var chat: ChatContainer
@export var user_list: ScrollContainer

@export var back_button: Button

@export_group("Sounds")
@export var click_sfx: AudioStreamPlayer
@export var game_start_sfx: AudioStreamPlayer

var loading_scene: PackedScene = load("res://game/loading_screen.tscn")
var main_menu_scene: PackedScene = load(ProjectSettings.get_setting("blazium/game/main_scene", "res://addons/blazium_shared_menus/main_menu/main_menu.tscn"))

var peer_to_kick: String
var state_was_started: bool = false
var exit_popup: CustomDialog
var kick_popup: CustomDialog


func _ready() -> void:
	game_start_sfx.play()

	private_checkbutton.visible = GlobalLobbyClient.is_host()
	private_checkbutton.set_pressed_no_signal(GlobalLobbyClient.lobby.sealed)

	GlobalLobbyClient.lobby_sealed.connect(_lobby_sealed)
	GlobalLobbyClient.lobby_left.connect(_lobby_left)
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	# Player list
	GlobalLobbyClient.peer_joined.connect(_peer_joined)
	GlobalLobbyClient.peer_left.connect(_peer_left)
	load_peers(GlobalLobbyClient.peers)

	exit_popup = CustomDialog.new("Are You Sure You Want To Exit?")
	exit_popup.name = "ExitPopup"
	exit_popup.cancelled.connect(_on_exit_popup_cancelled)
	exit_popup.confirmed.connect(_on_exit_popup_confirmed)
	exit_popup.hide()
	get_tree().current_scene.get_child(0).add_child(exit_popup, false, Node.INTERNAL_MODE_BACK)

	kick_popup = CustomDialog.new("Kick Player?")
	kick_popup.name = "KickPopup"
	kick_popup.cancelled.connect(_on_kick_popup_cancelled)
	kick_popup.confirmed.connect(_on_kick_popup_confirm)
	kick_popup.hide()
	get_tree().current_scene.get_child(0).add_child(kick_popup, false, Node.INTERNAL_MODE_BACK)

	_set_fallback_focus(chat.chat_text)

func _lobby_sealed(sealed: bool):
	private_checkbutton.set_pressed_no_signal(sealed)


func _lobby_left(_kicked: bool):
	if is_inside_tree():
		await get_tree().process_frame
		get_tree().change_scene_to_packed(main_menu_scene)


func leave_lobby():
	await GlobalLobbyClient.leave_lobby().finished


func kick_peer(peer: LobbyPeer) -> void:
	if peer.id == GlobalLobbyClient.peer.id:
		return
	peer_to_kick = peer.id
	kick_popup.text = "Kick %s?" % peer.user_data.get("name", "")
	_update_last_focus()
	kick_popup.show()


func _disconnected_from_server(_reason: String):
	if is_inside_tree():
		await get_tree().process_frame
		get_tree().change_scene_to_packed(loading_scene)


func _on_back_pressed() -> void:
	click_sfx.play()
	exit_popup.show()
	exit_popup.cancel_button.grab_focus()


func _physics_process(delta: float) -> void:
	# Checking this in inpus results in it being ran much more often than needed.
	if Input.is_action_just_pressed("ui_cancel"):
		if exit_popup.visible:
			exit_popup.visible = false
			_on_exit_popup_cancelled()
		else:
			exit_popup.show()
			exit_popup.cancel_button.grab_focus()


func _on_exit_popup_cancelled() -> void:
	click_sfx.play()
	back_button.grab_focus()


func _on_exit_popup_confirmed() -> void:
	click_sfx.play()
	leave_lobby()


func _play_click_sound() -> void:
	click_sfx.play()


func _on_private_toggled(toggled_on: bool) -> void:
	click_sfx.play()
	await GlobalLobbyClient.set_lobby_sealed(toggled_on).finished


func _on_kick_popup_cancelled() -> void:
	click_sfx.play()
	_restore_last_focus()


func _on_kick_popup_confirm() -> void:
	click_sfx.play()
	await GlobalLobbyClient.kick_peer(peer_to_kick).finished
	_restore_last_focus()


func _peer_joined(_peer: LobbyPeer):
	load_peers(GlobalLobbyClient.peers)


func _peer_left(_peer: LobbyPeer, _kicked: bool):
	load_peers(GlobalLobbyClient.peers)


func load_peers(peers: Array[LobbyPeer]):
	for child in player_list.get_children():
		child.queue_free()
	for peer in peers:
		var user_node := user_element_scene.instantiate()
		user_node.peer_info = peer
		user_node.kick.connect(kick_peer)
		player_list.add_child(user_node)


func send_chat(peer_id: LobbyPeer, message: String):
	chat.append_message_to_chat(peer_id, message)
