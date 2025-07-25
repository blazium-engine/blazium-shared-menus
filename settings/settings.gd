@tool
extends BlaziumPanel

const max_avatars := 28

@export var game_tab_button : Button
@export var music_tab_button : Button

@export var disconnect_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var click_sound: AudioStreamPlayer
@export var mute_checkbutton: ToggledButton
@export var theme_mode: ToggledButton
@export var word_filter: ToggledButton
@export var box_settings: BoxContainer

@export var master_volume_slider : HSlider
@export var music_volume_slider : HSlider
@export var effect_volume_slider : HSlider

@export var game_settings_container : MarginContainer
@export var sound_settings_container : MarginContainer

var main_menu_scene: PackedScene = load("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")
var loading_scene: PackedScene = load("res://addons/blazium_shared_menus/loading_screen/loading_screen.tscn")

var disconnect_popup: CustomDialog

enum activeOptions {
	Game,
	Sound
}

var _active_options: activeOptions = activeOptions.Game

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	resized.connect(_on_resized)
	_on_resized()
	mute_checkbutton.set_pressed_no_signal(!SettingsAutoload.config.get_value("Settings", "mute", false))
	theme_mode.set_pressed_no_signal(SettingsAutoload.config.get_value("Settings", "light_mode", false))
	GlobalLobbyClient.update_theme(!theme_mode.toggle_mode)
	word_filter.set_pressed_no_signal(WordFilterAutoload.filter_enabled)
	mute_checkbutton._update_text_and_icon()
	theme_mode._update_text_and_icon()
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	
	master_volume_slider.value = SettingsAutoload.config.get_value("Settings","master_volume", 0.75)
	SoundController._get_instance()._set_master_volume(SettingsAutoload.config.get_value("Settings","master_volume", 0.75))
	
	music_volume_slider.value = SettingsAutoload.config.get_value("Settings","music_volume", 0.75)
	SoundController._get_instance()._set_music_volume(SettingsAutoload.config.get_value("Settings","music_volume", 0.75))
	
	effect_volume_slider.value = SettingsAutoload.config.get_value("Settings","effect_volume", 0.75)
	SoundController._get_instance()._set_effect_volume(SettingsAutoload.config.get_value("Settings","effect_volume", 0.75))
	


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
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(loading_scene)


func _on_button_disconnect_pressed() -> void:
	click_sound.play()
	disconnect_popup.show()
	disconnect_popup.confirm_button.grab_focus()


#func _on_switch_avatar(_dir: int) -> void:
	#click_sound.play()
	#avatar.frame = wrapi(avatar.frame + _dir, 0, max_avatars)
	#_update_other_avatars()
#
#
#func _update_other_avatars():
	#prev_avatar.frame = wrapi(avatar.frame - 1, 0, max_avatars)
	#next_avatar.frame = wrapi(avatar.frame + 1, 0, max_avatars)

func _tab_to_game_settings()->void:
	if _active_options == activeOptions.Game:
		return
	
	game_settings_container.visible = true
	sound_settings_container.visible = false

func _tab_to_sound_settings()->void:
	if _active_options == activeOptions.Sound:
		return
	
	game_settings_container.visible = false
	sound_settings_container.visible = true

func _on_back_pressed() -> void:
	#SettingsAutoload.config.set_value("Cosmetics", "avatar", avatar.frame)
	SettingsAutoload.save_config()
	#_on_button_save_pressed({"avatar": avatar.frame})
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_disconnect_popup_confirmed() -> void:
	click_sound.play()
	GlobalLobbyClient.reconnection_token = ""
	GlobalLobbyClient.disconnect_from_server()


func _on_disconnect_popup_cancelled() -> void:
	SoundController._get_instance()._play_sound("click")
	disconnect_button.grab_focus()


func _play_click_sound() -> void:
	SoundController._get_instance()._play_sound("click")


func _on_sounds_toggled(toggled_on: bool) -> void:
	SoundController._get_instance()._play_sound("click")
	SettingsAutoload.config.set_value("Settings", "mute", !toggled_on)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), !toggled_on)

func _master_volume_drag_ended(changed: bool)->void:
	pass

func _on_master_volume_changed(value: float)->void:
	SettingsAutoload.config.set_value("Settings", "master_volume", value)
	SoundController._get_instance()._set_master_volume(value)

func _on_music_volume_changed(value: float)->void:
	SettingsAutoload.config.set_value("Settings", "music_volume", value)
	SoundController._get_instance()._set_music_volume(value)

func _on_effect_volume_changed(value: float)->void:
	SettingsAutoload.config.set_value("Settings", "effect_volume", value)
	SoundController._get_instance()._set_effect_volume(value)

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

func _on_filter_toggled(toggled_on: bool) -> void:
	click_sound.play()
	WordFilterAutoload.set_filter_enabled(toggled_on)
