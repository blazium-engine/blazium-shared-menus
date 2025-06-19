@tool
extends BlaziumPanel

@export var lobby_grid: VBoxContainer
@export var ready_button: ToggledButton
@export var start_button: Button
@export var leave_button: Button
@export var lobby_label: Label
@export var lobby_max_players_label: Label
@export var lobby_title_line_edit: LineEdit
@export var lobby_password_line_edit: LineEdit
@export var lobby_id_button: Button
@export var reveal_lobby_id_button: Button
@export var copy_invite_link_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var points_to_win: Label
@export var click_sound: AudioStreamPlayer

@export var private_checkbutton: CheckButton
@export var password_line_edit: LineEdit
@export var max_players_label: Label
@export var title_label: LineEdit
@export var increment_button: Button
@export var decrement_button: Button

var loading_scene: PackedScene = load("res://game/loading_screen.tscn")
var main_menu_scene: PackedScene = load(ProjectSettings.get_setting("blazium/game/main_scene", "res://addons/blazium_shared_menus/main_menu/main_menu.tscn"))
var lobby_browser_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_browser/lobby_browser.tscn")
var game_scene: PackedScene = load("res://game/game.tscn")
var container_peer_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/container_peer.tscn")
var exit_popup: CustomDialog
var kick_popup: CustomDialog


var showing_password := false
var title := ""
var peer_to_kick: String


func update_title():
	lobby_label.text = GlobalLobbyClient.lobby.lobby_name + " " + \
			tr("lobby_player_count").format({
				players = GlobalLobbyClient.lobby.players,
				max_players = GlobalLobbyClient.lobby.max_players
			})
	lobby_title_line_edit.text = GlobalLobbyClient.lobby.lobby_name
	lobby_max_players_label.text = str(GlobalLobbyClient.lobby.max_players)


func is_everyone_ready():
	for peer in GlobalLobbyClient.peers:
		if not peer.ready:
			return false
	return true


func update_start_button():
	if not is_everyone_ready() or len(GlobalLobbyClient.peers) == 1:
		start_button.disabled = true
		if not is_everyone_ready():
			start_button.text = "lobby_requires_ready"
		else:
			start_button.text = "lobby_requires_players"
		start_button.theme_type_variation = ""
	else:
		start_button.disabled = false
		start_button.text = "lobby_start"
		start_button.theme_type_variation = "SelectedButton"
	


func _update_private_lobby_checkbox():
	private_checkbutton.set_pressed_no_signal(GlobalLobbyClient.lobby.sealed)
	if GlobalLobbyClient.lobby.sealed:
		private_checkbutton.text = "hidden_yes"
	else:
		private_checkbutton.text = "hidden_no"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var max_points = GlobalLobbyClient.lobby.tags.get("max_points", 0)
	#if max_points == 0:
	#	points_to_win.text = "Points to win: Infinite"
	#else:
	#	points_to_win.text = "Points to win: " + str(max_points)
	_update_private_lobby_checkbox()
	if GlobalLobbyClient.lobby.id == "":
		# Got here by mistake, go back
		_disconnected_from_server("")
	update_ready_button(GlobalLobbyClient.peer.ready)
	GlobalLobbyClient.peer_joined.connect(_peer_joined)
	GlobalLobbyClient.peer_left.connect(_peer_left)
	GlobalLobbyClient.lobby_left.connect(_lobby_left)
	GlobalLobbyClient.lobby_titled.connect(update_title)
	GlobalLobbyClient.lobby_resized.connect(update_title)
	GlobalLobbyClient.lobby_sealed.connect(_lobby_sealed)
	GlobalLobbyClient.received_lobby_data.connect(_received_lobby_data)
	GlobalLobbyClient.peer_ready.connect(_peer_ready)
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	if not GlobalLobbyClient.is_host():
		start_button.hide()
		lobby_title_line_edit.editable = false
		lobby_password_line_edit.editable = false
		private_checkbutton.disabled = true
		increment_button.disabled = true
		decrement_button.disabled = true
	if GlobalLobbyClient.lobby.password_protected:
		password_line_edit.text = "123456"
	for child in lobby_grid.get_children():
		child.queue_free()
	for peer in GlobalLobbyClient.peers:
		_add_peer_container(peer)
	# Call it once
	_received_lobby_data.call_deferred(GlobalLobbyClient.lobby.data)
	_set_fallback_focus(ready_button)


func _add_peer_container(peer: LobbyPeer):
	var peer_container := container_peer_scene.instantiate()
	peer_container.selected = GlobalLobbyClient.peer.id == peer.id
	peer_container.peer = peer
	peer_container.avatar = peer.user_data.get("avatar", 0)
	peer_container.platform = peer.platform
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
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(loading_scene)


func _lobby_left(_kicked: bool):
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _received_lobby_data(data: Dictionary):
	# Start game
	if data.get("game_state", "setup") != "setup":
		await get_tree().process_frame
		if is_inside_tree():
				get_tree().change_scene_to_packed(game_scene)


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
	kick_popup.text = tr("lobby_prompt_kick_player").format({player = peer.user_data.get("name", "")})
	_update_last_focus()
	kick_popup.show()


func _on_ready_pressed() -> void:
	click_sound.play()
	var new_ready = not GlobalLobbyClient.peer.ready
	var result: LobbyResult = await GlobalLobbyClient.set_lobby_ready(new_ready).finished

	if not result.has_error():
		update_ready_button(new_ready)


func _on_seal_pressed() -> void:
	click_sound.play()
	await GlobalLobbyClient.set_lobby_sealed(not GlobalLobbyClient.lobby.sealed).finished


func _lobby_sealed(_sealed: bool):
	_update_private_lobby_checkbox()


func _on_start_pressed() -> void:
	click_sound.play()
	await GlobalLobbyClient.lobby_call("start_game").finished


func _on_resized() -> void:
	if Engine.is_editor_hint():
		return
	var show_spacers = GlobalLobbyClient.is_portrait() || GlobalLobbyClient.breakpoint_1024()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers


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
	await GlobalLobbyClient.leave_lobby().finished


func _on_back_pressed() -> void:
	click_sound.play()
	exit_popup.show()
	exit_popup.confirm_button.grab_focus()


func _on_reveal_lobby_id_pressed() -> void:
	click_sound.play()
	if reveal_lobby_id_button.button_pressed:
		lobby_id_button.text = tr("code_copy").format({code = GlobalLobbyClient.lobby.id})
	else:
		lobby_id_button.text = "code_copy_hidden"


func _play_click_sound() -> void:
	click_sound.play()


func _on_private_toggled(toggled_on: bool) -> void:
	click_sound.play()
	await GlobalLobbyClient.set_lobby_sealed(toggled_on).finished


func _on_kick_popup_cancelled() -> void:
	click_sound.play()
	_restore_last_focus()


func _on_kick_popup_confirmed() -> void:
	click_sound.play()
	await GlobalLobbyClient.kick_peer(peer_to_kick).finished
	_restore_last_focus()


func _init() -> void:
	exit_popup = CustomDialog.new("menu_prompt_exit")
	exit_popup.name = "ExitPopup"
	exit_popup.cancelled.connect(_on_exit_popup_cancelled)
	exit_popup.confirmed.connect(_on_exit_popup_confirmed)
	exit_popup.hide()
	add_child(exit_popup, false, Node.INTERNAL_MODE_BACK)

	kick_popup = CustomDialog.new("lobby_prompt_kick")
	kick_popup.name = "KickPopup"
	kick_popup.cancelled.connect(_on_kick_popup_cancelled)
	kick_popup.confirmed.connect(_on_kick_popup_confirmed)
	kick_popup.hide()
	add_child(kick_popup, false, Node.INTERNAL_MODE_BACK)

func _on_copy_invite_link_pressed() -> void:
	click_sound.play()
	DisplayServer.clipboard_set("https://%s?code=%s" % [GameCredits.HOSTNAME, GlobalLobbyClient.lobby.id])

func _update_max_players_buttons(players):
	decrement_button.disabled = players == ProjectSettings.get_setting("blazium/game/max_players_min", 2)
	increment_button.disabled = players == ProjectSettings.get_setting("blazium/game/max_players_max", 10)

func _on_button_increment_pressed() -> void:
	click_sound.play()
	var player_limit := int(max_players_label.text)
	player_limit += 1
	var max_players = ProjectSettings.get_setting("blazium/game/max_players_max", 10)
	if player_limit > max_players:
		player_limit = max_players
	max_players_label.text = tr("players_max").format({players = player_limit})
	_update_max_players_buttons(player_limit)
	GlobalLobbyClient.set_max_players(player_limit)


func _on_button_decrement_pressed() -> void:
	click_sound.play()
	var player_limit := int(max_players_label.text)
	player_limit -= 1
	var min_players = ProjectSettings.get_setting("blazium/game/max_players_min", 2)
	if player_limit < min_players:
		player_limit = min_players
	max_players_label.text = tr("players_max").format({players = player_limit})
	_update_max_players_buttons(player_limit)
	GlobalLobbyClient.set_max_players(player_limit)

func _on_password_line_edit_text_submitted(new_text: String) -> void:
	await GlobalLobbyClient.set_password(new_text).finished

func _on_password_line_edit_text_changed(new_text: String) -> void:
	await GlobalLobbyClient.set_password(new_text).finished

func _on_title_text_submitted(new_text: String) -> void:
	await GlobalLobbyClient.set_title(new_text).finished

func _on_title_text_changed(new_text: String) -> void:
	await GlobalLobbyClient.set_title(new_text).finished

func _on_sealed_toggled(toggled_on: bool) -> void:
	await GlobalLobbyClient.set_lobby_sealed(toggled_on).finished
