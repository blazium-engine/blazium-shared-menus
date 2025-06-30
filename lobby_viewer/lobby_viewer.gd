@tool
extends BlaziumPanel

@export var lobby_grid: BoxContainer
@export var ready_button: ToggledButton
@export var start_button: Button
@export var leave_button: Button
@export var lobby_label: Label
@export var lobby_max_players_label: Label
@export var lobby_title_line_edit: LineEdit
@export var lobby_password_line_edit: LineEdit
@export var lobby_id_button: Button
@export var reveal_lobby_id_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var click_sound: AudioStreamPlayer

@export var private_checkbutton: CheckButton
@export var password_line_edit: LineEdit
@export var max_players_label: Label
@export var title_label: LineEdit
@export var increment_button: Button
@export var decrement_button: Button

@export var mode_options: OptionButton
@export var players_scrollcontainer: ScrollContainer

var loading_scene: PackedScene = load("res://addons/blazium_shared_menus/loading_screen/loading_screen.tscn")
var main_menu_scene: PackedScene = load("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")
var lobby_browser_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_browser/lobby_browser.tscn")
var game_scene: PackedScene = load("res://game/game.tscn")
var container_peer_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/container_peer.tscn")
var exit_popup: CustomDialog
var kick_popup: CustomDialog


var showing_password := false
var title := ""
var peer_to_kick: String


func update_title():
	lobby_label.text = WordFilterAutoload.filter_message(GlobalLobbyClient.lobby.lobby_name + " " + \
		str(GlobalLobbyClient.lobby.players) + "/" + str(GlobalLobbyClient.lobby.max_players))
	# The host already has this updated
	if !GlobalLobbyClient.is_host():
		lobby_title_line_edit.text = WordFilterAutoload.filter_message(GlobalLobbyClient.lobby.lobby_name)
	lobby_max_players_label.text = tr("players_max").format({players = GlobalLobbyClient.lobby.max_players})


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


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_update_private_lobby_checkbox()
	if GlobalLobbyClient.lobby.id == "":
		# Got here by mistake, go back
		_disconnected_from_server("")
	lobby_id_button.text = tr("code_copy").format({code = "••••••••"})
	update_ready_button(GlobalLobbyClient.peer.ready)
	GlobalLobbyClient.peer_joined.connect(_peer_joined)
	GlobalLobbyClient.peer_left.connect(_peer_left)
	GlobalLobbyClient.lobby_left.connect(_lobby_left)
	GlobalLobbyClient.lobby_titled.connect(_lobby_titled)
	GlobalLobbyClient.lobby_resized.connect(_lobby_resized)
	GlobalLobbyClient.lobby_sealed.connect(_lobby_sealed)
	GlobalLobbyClient.received_lobby_data.connect(_received_lobby_data)
	GlobalLobbyClient.peer_ready.connect(_peer_ready)
	GlobalLobbyClient.lobby_tagged.connect(_lobby_tagged)
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	GlobalLobbyClient.lobby_hosted.connect(_lobby_hosted)
	for peer in GlobalLobbyClient.peers:
		if peer.id == GlobalLobbyClient.lobby.host:
			_lobby_hosted(peer)
	if GlobalLobbyClient.lobby.password_protected:
		password_line_edit.text = "123456"
	for child in lobby_grid.get_children():
		child.queue_free()
	for peer in GlobalLobbyClient.peers:
		_add_peer_container(peer)
	# Call it once
	_received_lobby_data.call_deferred(GlobalLobbyClient.lobby.data)
	_set_fallback_focus(ready_button)

func _lobby_hosted(peer: LobbyPeer):
	# Host changed, reload scene
	var is_host := GlobalLobbyClient.is_host()
	start_button.visible = is_host
	mode_options.disabled = !is_host
	lobby_title_line_edit.editable = is_host
	lobby_password_line_edit.editable = is_host
	private_checkbutton.disabled = !is_host
	increment_button.disabled = !is_host
	decrement_button.disabled = !is_host

func _add_peer_container(peer: LobbyPeer):
	var peer_container := container_peer_scene.instantiate()
	peer_container.selected = GlobalLobbyClient.peer.id == peer.id
	peer_container.enable_ready = true
	peer_container.peer = peer
	peer_container.kick.connect(kick_peer)
	lobby_grid.add_child(peer_container)
	update_title()
	update_start_button()

func _lobby_tagged(tags: Dictionary):
	match tags.get("game_mode", "normal_mode"):
		"normal_mode":
			mode_options.selected = 0
		"normal_abunch_hanging":
			mode_options.selected = 1
		"normal_all_or_nothing":
			mode_options.selected = 2
		"normal_last_wrong_dies":
			mode_options.selected = 3

func _lobby_resized(max_peers: int):
	update_title()

func _lobby_titled(title: String):
	update_title()

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
	var show_spacers = GlobalLobbyClient.ui_breakpoint()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers
	if show_spacers:
		players_scrollcontainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		players_scrollcontainer.size_flags_vertical = Control.SIZE_FILL


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
		lobby_id_button.text = tr("code_copy").format({code = "••••••••"})


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


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			GlobalLobbyClient.add_lobby_tags({"game_mode": "normal_mode"})
		1:
			GlobalLobbyClient.add_lobby_tags({"game_mode": "normal_abunch_hanging"})
		2:
			GlobalLobbyClient.add_lobby_tags({"game_mode": "normal_all_or_nothing"})
		3:
			GlobalLobbyClient.add_lobby_tags({"game_mode": "normal_last_wrong_dies"})
