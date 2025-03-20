@tool
extends BlaziumPanel

const max_avatars := 28

@export var logs: Label
@export var name_label: LineEdit
@export var edit_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var prev_avatar: Avatar
@export var avatar: Avatar
@export var next_avatar: Avatar
@export var click_sound: AudioStreamPlayer
@export var debug_info_checkbutton: ToggledButton
@export var mute_checkbutton: ToggledButton
@export var theme_mode: ToggledButton

var main_menu_scene: PackedScene = load("res://menus/main_menu/main_menu.tscn")

var config: ConfigFile
var disconnect_popup: CustomDialog

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	config = ConfigFile.new()
	config.load("user://blazium.cfg")
	mute_checkbutton.set_pressed_no_signal(config.get_value("Settings", "mute", false))
	theme_mode.set_pressed_no_signal(config.get_value("Settings", "light_mode", false))
	mute_checkbutton._update_text_and_icon()
	debug_info_checkbutton.set_pressed_no_signal(GlobalLobbyClient.show_debug)
	debug_info_checkbutton._update_text_and_icon()
	name_label.text = GlobalLobbyClient.peer.user_data.get("name", "")
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	avatar.frame = GlobalLobbyClient.peer.user_data.get("avatar", 0)
	_update_other_avatars()
	if not (OS.get_name() in ["Android", "iOS"]):
		name_label.grab_focus()


func _on_resized() -> void:
	var show_spacers = size.x > 600
	left_spacer.visible = show_spacers
	right_spacer.visible = show_spacers


func _on_button_save_pressed(data: Dictionary) -> void:
	click_sound.play()
	var result: LobbyResult = await GlobalLobbyClient.add_peer_user_data(data).finished
	name_label.text = GlobalLobbyClient.peer.user_data.get("name", "")
	logs.text = result.error
	logs.visible = GlobalLobbyClient.show_debug


func _on_edit_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		name_label.editable = true
		edit_button.text = "Save"
		name_label.edit()
		name_label.select_all()
	else:
		if name_label.editable:
			_on_button_save_pressed({"name": name_label.text})
		name_label.editable = false
		edit_button.text = "Edit"


func _on_name_text_submitted(_new_text: String) -> void:
	click_sound.play()
	edit_button.button_pressed = false # to trigger button toggle


func _shortcut_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if disconnect_popup.visible:
			disconnect_popup.hide()
		else:
			_on_back_pressed()


func _disconnected_from_server(_reason: String):
	await get_tree().create_timer(1).timeout
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_button_disconnect_pressed() -> void:
	click_sound.play()
	disconnect_popup.show()


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
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_disconnect_popup_confirmed() -> void:
	click_sound.play()
	GlobalLobbyClient.reconnection_token = ""
	GlobalLobbyClient.disconnect_from_server()


func _play_click_sound() -> void:
	click_sound.play()


func _on_sounds_toggled(toggled_on: bool) -> void:
	click_sound.play()
	config.set_value("Settings", "mute", toggled_on)
	config.save("user://blazium.cfg")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggled_on)


func _on_show_debug_toggled(toggled_on: bool) -> void:
	click_sound.play()
	GlobalLobbyClient.show_debug = toggled_on


func _on_theme_mode_toggled(toggled_on: bool) -> void:
	click_sound.play()
	GlobalLobbyClient.update_theme(toggled_on)
	config.set_value("Settings", "light_mode", toggled_on)
	config.save("user://blazium.cfg")


func _init() -> void:
	disconnect_popup = CustomDialog.new("Are You Sure You Want To Disconnect?")
	disconnect_popup.name = "DisconnectPopup"
	disconnect_popup.cancelled.connect(_play_click_sound)
	disconnect_popup.confirmed.connect(_on_disconnect_popup_confirmed)
	disconnect_popup.hide()
	add_child(disconnect_popup, false, Node.INTERNAL_MODE_BACK)
