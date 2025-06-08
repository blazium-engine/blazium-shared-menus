@tool
extends BlaziumPanel

@export var lobby_grid: VBoxContainer
@export var logs: Label
@export var lobby_id: LineEdit
@export var left_spacer: Control
@export var right_spacer: Control
@export var filter_foldable_container: FoldableContainer
@export var click_sound: AudioStreamPlayer

var loading_scene: PackedScene = load("res://game/loading_screen.tscn")
var main_menu_scene: PackedScene = load(ProjectSettings.get_setting("blazium/game/main_scene", "res://addons/blazium_shared_menus/main_menu/main_menu.tscn"))
var lobby_creator_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_creator/lobby_creator.tscn")
var container_lobby_scene: PackedScene = preload("res://addons/blazium_shared_menus/lobby_browser/container_lobby.tscn")
var lobby_viewer: PackedScene = preload("res://addons/blazium_shared_menus/lobby_viewer/lobby_viewer.tscn")
var wrong_id_popup: CustomDialog
var password_popup: CustomDialog
var password_log := Label.new()
var password_line_edit := LineEdit.new()

var hide_full:= false
var hide_private:= false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	load_lobbies()
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	GlobalLobbyClient.lobbies_listed.connect(_lobbies_listed)
	GlobalLobbyClient.lobby_joined.connect(_lobby_joined)
	filter_foldable_container.grab_focus()


func _lobby_joined(_lobby: LobbyInfo, _peers: Array[LobbyPeer]):
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_viewer)


func _lobbies_listed(lobbies: Array[LobbyInfo]):
	for child in lobby_grid.get_children():
		child.queue_free()
	for lobby in lobbies:
		# Hide full lobbies is asked for
		if hide_full and lobby.max_players == lobby.players:
			continue
		if hide_private and lobby.password_protected:
			continue
		if lobby.tags.get("game_mode", "") == "competitive_abunch_hanging":
			continue
		var lobby_container := container_lobby_scene.instantiate()
		lobby_container.lobby = lobby
		lobby_container.password_popup = password_popup
		lobby_container.logs = logs
		lobby_grid.add_child(lobby_container)


func load_lobbies() -> void:
	var result: LobbyResult = await GlobalLobbyClient.list_lobbies().finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error


func _on_resized() -> void:
	var show_spacers = GlobalLobbyClient.breakpoint_1024()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers


func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()


func _disconnected_from_server(_reason: String):
	if is_inside_tree():
		get_tree().change_scene_to_packed(loading_scene)


func _on_back_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_hide_full_pressed() -> void:
	click_sound.play()
	hide_full = not hide_full
	load_lobbies()


func _on_hide_private_pressed() -> void:
	click_sound.play()
	hide_private = not hide_private
	load_lobbies()


func _on_join_lobby_pressed() -> void:
	click_sound.play()
	var result: ViewLobbyResult = await GlobalLobbyClient.join_lobby(lobby_id.text, "").finished

	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	if result.has_error():
		if result.error == "Invalid lobby password":
			password_popup.show()
			password_popup.confirm_button.grab_focus()
		else:
			wrong_id_popup.show()
			wrong_id_popup.confirm_button.grab_focus()


func _play_click_sound():
	click_sound.play()


func _on_password_popup_cancelled() -> void:
	click_sound.play()
	password_log.text = ""
	password_log.hide()
	filter_foldable_container.grab_focus()


func _on_password_popup_confirmed() -> void:
	click_sound.play()
	var result: ViewLobbyResult = await GlobalLobbyClient.join_lobby(password_popup.get_meta("lobby_id"), password_line_edit.text).finished
	password_log.visible = GlobalLobbyClient.show_debug
	password_log.text = result.error
	filter_foldable_container.grab_focus()


func _popup_acknowledged() -> void:
	click_sound.play()
	filter_foldable_container.grab_focus()


func _init() -> void:
	wrong_id_popup = CustomDialog.new("Wrong Game Code", "Continue", "")
	wrong_id_popup.confirm_button.user_icon = "keyboard_double_arrow_right"
	wrong_id_popup.confirm_button.theme_type_variation = "SelectedButton"
	wrong_id_popup.confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrong_id_popup.confirmed.connect(_popup_acknowledged)
	wrong_id_popup.hide()
	add_child(wrong_id_popup, false, Node.INTERNAL_MODE_BACK)
	password_popup = CustomDialog.new("Game Is Password Protected", "Enter", "Cancel")
	password_line_edit.placeholder_text = "Password"
	password_line_edit.secret = true
	password_popup.main_vb.add_child(password_line_edit)
	password_log.hide()
	password_popup.main_vb.add_child(password_log)
	password_popup.confirm_button.theme_type_variation = "SelectedButton"
	password_popup.confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	password_popup.cancelled.connect(_on_password_popup_cancelled)
	password_popup.confirmed.connect(_on_password_popup_confirmed)
	password_popup.hide()
	add_child(password_popup, false, Node.INTERNAL_MODE_BACK)
