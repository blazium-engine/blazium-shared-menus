@tool
extends BlaziumPanel

const max_avatars := 28

@export var disconnect_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var prev_avatar: Avatar
@export var avatar: Avatar
@export var next_avatar: Avatar
@export var click_sound: AudioStreamPlayer
@export var mute_checkbutton: CheckButton
@export var theme_mode: CheckButton

var main_menu_scene: PackedScene = load(ProjectSettings.get_setting("blazium/game/main_scene", "res://addons/blazium_shared_menus/main_menu/main_menu.tscn"))
var loading_scene: PackedScene = load("res://game/loading_screen.tscn")

var disconnect_popup: CustomDialog


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	resized.connect(_on_resized)
	_on_resized()
	mute_checkbutton.set_pressed_no_signal(!SettingsAutoload.config.get_value("Settings", "mute", false))
	theme_mode.set_pressed_no_signal(SettingsAutoload.config.get_value("Settings", "light_mode", false))
	mute_checkbutton._update_text_and_icon()
	theme_mode._update_text_and_icon()
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	avatar.frame = GlobalLobbyClient.peer.user_data.get("avatar", 0)
	_update_other_avatars()


func _on_resized() -> void:
	var show_spacers = GlobalLobbyClient.ui_breakpoint()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers


func _on_button_save_pressed(data: Dictionary) -> void:
	click_sound.play()
	await GlobalLobbyClient.add_peer_user_data(data).finished


func _shortcut_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if disconnect_popup.visible:
			disconnect_popup.hide()
		else:
			_on_back_pressed()


func _disconnected_from_server(_reason: String):
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(loading_scene)


func _on_button_disconnect_pressed() -> void:
	click_sound.play()
	disconnect_popup.show()
	disconnect_popup.confirm_button.grab_focus()


func _on_switch_avatar(_dir: int) -> void:
	click_sound.play()
	avatar.frame = wrapi(avatar.frame + _dir, 0, max_avatars)
	_update_other_avatars()


func _update_other_avatars():
	prev_avatar.frame = wrapi(avatar.frame - 1, 0, max_avatars)
	next_avatar.frame = wrapi(avatar.frame + 1, 0, max_avatars)


func _on_back_pressed() -> void:
	_on_button_save_pressed({"avatar": avatar.frame})
	click_sound.play()
	await click_sound.finished
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)
	# TODO: Decouple Hangman cosmetics from shared menus
	CosmeticAutoload.save_to_config()
	SettingsAutoload.save_config()


func _on_disconnect_popup_confirmed() -> void:
	click_sound.play()
	GlobalLobbyClient.reconnection_token = ""
	GlobalLobbyClient.disconnect_from_server()


func _on_disconnect_popup_cancelled() -> void:
	click_sound.play()
	disconnect_button.grab_focus()


func _play_click_sound() -> void:
	click_sound.play()


func _on_sounds_toggled(toggled_on: bool) -> void:
	click_sound.play()
	SettingsAutoload.config.set_value("Settings", "mute", !toggled_on)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), !toggled_on)


func _on_theme_mode_toggled(toggled_on: bool) -> void:
	click_sound.play()
	GlobalLobbyClient.update_theme(toggled_on)
	SettingsAutoload.config.set_value("Settings", "light_mode", toggled_on)


func _init() -> void:
	disconnect_popup = CustomDialog.new("settings_prompt_disconnect")
	disconnect_popup.name = "DisconnectPopup"
	disconnect_popup.cancelled.connect(_on_disconnect_popup_cancelled)
	disconnect_popup.confirmed.connect(_on_disconnect_popup_confirmed)
	disconnect_popup.hide()
	add_child(disconnect_popup, false, Node.INTERNAL_MODE_BACK)


# TODO: Decouple Hangman cosmetics from shared menus
func _on_hair_pressed(color_hex: String) -> void:
	CosmeticAutoload.character_cosmetics.hair_color = Color(color_hex)
	
