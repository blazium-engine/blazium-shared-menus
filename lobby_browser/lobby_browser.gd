@tool
extends BlaziumPanel

@export var lobby_grid: VBoxContainer
@export var lobby_id: LineEdit
@export var left_spacer: Control
@export var right_spacer: Control
@export var filter_foldable_container: FoldableContainer
@export var click_sound: AudioStreamPlayer

var loading_scene: PackedScene = load("res://addons/blazium_shared_menus/loading_screen/loading_screen.tscn")
var main_menu_scene: PackedScene = load("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")
var lobby_creator_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_creator/lobby_creator.tscn")
var container_lobby_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_browser/container_lobby.tscn")
var lobby_viewer: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/lobby_viewer.tscn")
var wrong_id_popup: CustomDialog
var lobby_full_popup: CustomDialog
var password_popup: CustomDialog
var password_line_edit := LineEdit.new()

var hide_private:= false
var hide_other_lang:= true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	resized.connect(_on_resized)
	_on_resized()
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	GlobalLobbyClient.lobbies_listed.connect(_lobbies_listed)
	GlobalLobbyClient.lobby_joined.connect(_lobby_joined)
	load_lobbies()
	filter_foldable_container.grab_focus()


func _lobby_joined(_lobby: LobbyInfo, _peers: Array[LobbyPeer]):
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(lobby_viewer)


func _lobbies_listed(lobbies: Array[LobbyInfo]):
	for child in lobby_grid.get_children():
		child.queue_free()
	for lobby in lobbies:
		if lobby.max_players == lobby.players:
			continue
		if hide_private and lobby.password_protected:
			continue
		if lobby.tags.get("game_mode", "") == "competitive_abunch_hanging":
			continue
		if (lobby.tags.get("lang", "") != TranslationServer.get_locale().split("_")[0]) && hide_other_lang:
			continue
		var lobby_container := container_lobby_scene.instantiate()
		lobby_container.lobby = lobby
		lobby_container.password_popup = password_popup
		lobby_container.lobby_full_popup = lobby_full_popup
		lobby_grid.add_child(lobby_container)


func load_lobbies() -> void:
	await GlobalLobbyClient.list_lobbies().finished


func _on_resized() -> void:
	var show_spacers = GlobalLobbyClient.ui_breakpoint()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers


func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()


func _disconnected_from_server(_reason: String):
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(loading_scene)


func _on_back_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)

func _on_hide_private_pressed() -> void:
	click_sound.play()
	hide_private = not hide_private
	load_lobbies()


func _on_join_lobby_pressed() -> void:
	click_sound.play()
	var result: ViewLobbyResult = await GlobalLobbyClient.join_lobby(lobby_id.text, "").finished

	if result.has_error():
		if result.error == "Invalid password":
			password_popup.show()
			password_popup.set_meta("lobby_id", lobby_id.text)
			password_popup.confirm_button.grab_focus()
		elif result.error == "Lobby is full":
			lobby_full_popup.show()
			lobby_full_popup.confirm_button.grab_focus()
		else:
			wrong_id_popup.show()
			wrong_id_popup.confirm_button.grab_focus()


func _play_click_sound():
	click_sound.play()


func _on_password_popup_cancelled() -> void:
	click_sound.play()
	filter_foldable_container.grab_focus()


func _on_password_popup_confirmed() -> void:
	click_sound.play()
	var result: ViewLobbyResult = await GlobalLobbyClient.join_lobby(password_popup.get_meta("lobby_id"), password_line_edit.text).finished
	if result.has_error():
		if result.error == "Invalid password":
			password_popup.show()
			password_popup.confirm_button.grab_focus()
		else:
			wrong_id_popup.show()
			wrong_id_popup.confirm_button.grab_focus()
	else:
		filter_foldable_container.grab_focus()


func _popup_acknowledged() -> void:
	click_sound.play()
	filter_foldable_container.grab_focus()


func _init() -> void:
	wrong_id_popup = CustomDialog.new("lobby_prompt_wrong_code", "prompt_continue", "")
	wrong_id_popup.confirm_button.user_icon = "keyboard_double_arrow_right"
	wrong_id_popup.confirm_button.theme_type_variation = "SelectedButton"
	wrong_id_popup.confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrong_id_popup.confirmed.connect(_popup_acknowledged)
	wrong_id_popup.hide()
	add_child(wrong_id_popup, false, Node.INTERNAL_MODE_BACK)
	password_popup = CustomDialog.new("lobby_prompt_password_protected", "prompt_enter", "prompt_cancel")
	password_line_edit.placeholder_text = "password_placeholder"
	password_line_edit.secret = true
	password_popup.main_vb.add_child(password_line_edit)
	password_popup.confirm_button.theme_type_variation = "SelectedButton"
	password_popup.confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	password_popup.cancelled.connect(_on_password_popup_cancelled)
	password_popup.confirmed.connect(_on_password_popup_confirmed)
	password_popup.hide()
	add_child(password_popup, false, Node.INTERNAL_MODE_BACK)
	lobby_full_popup = CustomDialog.new("lobby_prompt_full", "prompt_continue", "")
	lobby_full_popup.confirm_button.user_icon = "keyboard_double_arrow_right"
	lobby_full_popup.confirm_button.theme_type_variation = "SelectedButton"
	lobby_full_popup.confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lobby_full_popup.confirmed.connect(_popup_acknowledged)
	lobby_full_popup.hide()
	add_child(lobby_full_popup, false, Node.INTERNAL_MODE_BACK)


func _on_hide_other_lang_pressed() -> void:
	click_sound.play()
	hide_other_lang = not hide_other_lang
	load_lobbies()
