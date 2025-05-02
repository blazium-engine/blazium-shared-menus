@tool
extends BlaziumPanel

@export var lobby_grid: VBoxContainer
@export var logs: Label
@export var ready_button: ToggledButton
@export var start_button: Button
@export var leave_button: Button
@export var lobby_label: Label
@export var lobby_id_button: Button
@export var reveal_lobby_id_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var private_checkbutton: CheckBox
@export var points_to_win: Label
@export var click_sound: AudioStreamPlayer
@export var invite_panel: Panel

var main_menu_scene: PackedScene = load("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")
var lobby_browser_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_browser/lobby_browser.tscn")
var game_scene: PackedScene = load("res://game/game.tscn")
var container_peer_scene: PackedScene = preload("res://addons/blazium_shared_menus/lobby_viewer/container_peer.tscn")
var exit_popup: CustomDialog
var kick_popup: CustomDialog


var showing_password := false
var title := ""
var peer_to_kick: String


func update_title():
	lobby_label.text = GlobalLobbyClient.lobby.lobby_name + " " + \
			str(GlobalLobbyClient.lobby.players) + "/" + \
			str(GlobalLobbyClient.lobby.max_players)


func is_everyone_ready():
	for peer in GlobalLobbyClient.peers:
		if not peer.ready:
			return false
	return true


func update_start_button():
	start_button.disabled = not is_everyone_ready() or len(GlobalLobbyClient.peers) == 1


func _update_private_lobby_checkbox():
	private_checkbutton.set_pressed_no_signal(GlobalLobbyClient.lobby.sealed)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	private_checkbutton.visible = GlobalLobbyClient.is_host()
	var max_points = GlobalLobbyClient.lobby.tags.get("max_points", 0)
	if max_points == 0:
		points_to_win.text = "Points to win: Infinite"
	else:
		points_to_win.text = "Points to win: " + str(max_points)
	_update_private_lobby_checkbox()
	if GlobalLobbyClient.lobby.id == "":
		# Got here by mistake, go back
		_disconnected_from_server("")
	update_ready_button(GlobalLobbyClient.peer.ready)
	GlobalLobbyClient.peer_joined.connect(_peer_joined)
	GlobalLobbyClient.peer_left.connect(_peer_left)
	GlobalLobbyClient.lobby_left.connect(_lobby_left)
	GlobalLobbyClient.lobby_sealed.connect(_lobby_sealed)
	GlobalLobbyClient.received_lobby_data.connect(_received_lobby_data)
	GlobalLobbyClient.peer_ready.connect(_peer_ready)
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	if not GlobalLobbyClient.is_host():
		start_button.hide()
	for child in lobby_grid.get_children():
		child.queue_free()
	for peer in GlobalLobbyClient.peers:
		_add_peer_container(peer)
	# Call it once
	_received_lobby_data.call_deferred(GlobalLobbyClient.lobby.data)


func _add_peer_container(peer: LobbyPeer):
	var peer_container := container_peer_scene.instantiate()
	peer_container.selected = GlobalLobbyClient.peer.id == peer.id
	peer_container.peer = peer
	peer_container.avatar = peer.user_data.get("avatar", 0)
	peer_container.logs = logs
	peer_container.kick.connect(kick_peer)
	lobby_grid.add_child(peer_container)
	update_title()
	update_start_button()


func _peer_joined(peer: LobbyPeer):
	_add_peer_container(peer)


func _peer_left(peer: LobbyPeer, _kicked: bool):
	for child in lobby_grid.get_children():
		if child.peer.id == peer.id:
			child.queue_free()
	update_title()
	update_start_button()


func _peer_ready(_peer: LobbyPeer, _p_ready: bool):
	update_start_button()


func _disconnected_from_server(_reason: String):
	if is_inside_tree():
		get_tree().change_scene_to_packed.call_deferred(main_menu_scene)


func _lobby_left(_kicked: bool):
	if is_inside_tree():
		get_tree().change_scene_to_packed.call_deferred(main_menu_scene)


func _received_lobby_data(data: Dictionary):
	# Start game
	if data.get("game_state", "setup") != "setup":
		if is_inside_tree():
			get_tree().change_scene_to_packed.call_deferred(game_scene)


func update_ready_button(is_ready: bool):
	ready_button.button_pressed = is_ready
	if is_ready:
		ready_button.theme_type_variation = ""
	else:
		ready_button.theme_type_variation = "SelectedButton"


func kick_peer(peer: LobbyPeer) -> void:
	if peer.id == GlobalLobbyClient.peer.id:
		return
	peer_to_kick = peer.id
	kick_popup.text = "Kick %s?" % peer.user_data.get("name", "")
	kick_popup.show()


func _on_ready_pressed() -> void:
	click_sound.play()
	var new_ready = not GlobalLobbyClient.peer.ready
	var result: LobbyResult = await GlobalLobbyClient.set_lobby_ready(new_ready).finished

	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	if not result.has_error():
		update_ready_button(new_ready)


func _on_seal_pressed() -> void:
	click_sound.play()
	var result: LobbyResult = await GlobalLobbyClient.set_lobby_sealed(not GlobalLobbyClient.lobby.sealed).finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error


func _lobby_sealed(_sealed: bool):
	_update_private_lobby_checkbox()


func _on_start_pressed() -> void:
	click_sound.play()
	var result: ScriptedLobbyResult = await GlobalLobbyClient.lobby_call("start_game").finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error


func _on_resized() -> void:
	var show_spacers = size.x > 600
	left_spacer.visible = show_spacers
	right_spacer.visible = show_spacers


func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		if exit_popup.visible:
			exit_popup.visible = false
			_on_exit_popup_cancelled()
		else:
			_on_back_pressed()


func _on_label_lobby_id_pressed() -> void:
	click_sound.play()
	showing_password = not showing_password
	DisplayServer.clipboard_set(GlobalLobbyClient.lobby.id)


func _on_exit_popup_cancelled() -> void:
	click_sound.play()
	leave_button.grab_focus()


func _on_exit_popup_confirmed() -> void:
	click_sound.play()
	var result: LobbyResult = await GlobalLobbyClient.leave_lobby().finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error


func _on_back_pressed() -> void:
	click_sound.play()
	exit_popup.show()
	exit_popup.confirm_button.grab_focus()


func _on_reveal_lobby_id_pressed() -> void:
	click_sound.play()
	if reveal_lobby_id_button.button_pressed:
		lobby_id_button.text = "Copy Code: " + GlobalLobbyClient.lobby.id
	else:
		lobby_id_button.text = "Copy Code: ••••••••"


func _play_click_sound() -> void:
	click_sound.play()


func _on_private_toggled(toggled_on: bool) -> void:
	click_sound.play()
	var result: LobbyResult = await GlobalLobbyClient.set_lobby_sealed(toggled_on).finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error


func _on_kick_popup_cancelled() -> void:
	click_sound.play()
	ready_button.grab_focus()


func _on_kick_popup_confirmed() -> void:
	click_sound.play()
	var result: LobbyResult = await GlobalLobbyClient.kick_peer(peer_to_kick).finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	ready_button.grab_focus()


func _init() -> void:
	exit_popup = CustomDialog.new("Are You Sure You Want To Exit?")
	exit_popup.name = "ExitPopup"
	exit_popup.cancelled.connect(_on_exit_popup_cancelled)
	exit_popup.confirmed.connect(_on_exit_popup_confirmed)
	exit_popup.hide()
	add_child(exit_popup, false, Node.INTERNAL_MODE_BACK)
	kick_popup = CustomDialog.new("Kick Player?")
	kick_popup.name = "KickPopup"
	kick_popup.cancelled.connect(_on_kick_popup_cancelled)
	kick_popup.confirmed.connect(_on_kick_popup_confirmed)
	kick_popup.hide()
	add_child(kick_popup, false, Node.INTERNAL_MODE_BACK)


func _on_close_invite_panel_pressed() -> void:
	click_sound.play()
	invite_panel.hide()


func _on_open_invite_panel_pressed() -> void:
	click_sound.play()
	invite_panel.show()


func _on_copy_invite_link_pressed() -> void:
	click_sound.play()
	DisplayServer.clipboard_set("https://%s?code=%s" % [GameCredits.HOSTNAME, GlobalLobbyClient.lobby.id])
