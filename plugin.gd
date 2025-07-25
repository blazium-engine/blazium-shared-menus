@tool
extends EditorPlugin


func _enter_tree() -> void:
	set_default_setting("blazium/game/max_players_min", "Minimum players needed to start a game.", 2)
	set_default_setting("blazium/game/max_players_max", "Maximum players needed to start a game.", 10)
	set_default_setting("blazium/game/max_players_default", "Default players set when creating a lobby.", 6)
	set_default_setting("blazium/game/lobby_server_local", "Use local Lobby Server.", false)
	set_default_setting("blazium/game/store_name", "Set in actions to store name.", "")
	set_default_setting("blazium/game/pogr_client_id", "Your pogr client id. Used for analytics.", "")
	set_default_setting("blazium/game/pogr_build_id", "Your pogr build id. Used for analytics.", "")
	set_default_setting("blazium/game/login_game_id", "Your login game_id. Used for authentication.", "")
	set_default_setting("blazium/game/lobby_game_id", "Your lobby game_id. Used for multiplayer.", "")
	set_default_setting("blazium/game/menu_competitive_enabled", "Should it show the competitive mode?", false)
	set_default_setting("blazium/game/lobby_modes", "Lobby Modes", ["normal_mode"])
	
	add_autoload_singleton.call_deferred("SettingsAutoload", "res://addons/blazium_shared_menus/settings/settings_autoload.gd")
	add_autoload_singleton.call_deferred("GlobalLobbyClient", "res://addons/blazium_shared_menus/services/lobby_client.tscn")
	add_autoload_singleton.call_deferred("WordFilterAutoload", "res://addons/blazium_shared_menus/settings/word_filter_autoload.gd")
	ProjectSettings.set("display/window/size/viewport_width", 1600)
	ProjectSettings.set("display/window/size/viewport_height", 900)
	ProjectSettings.set("display/window/size/mode", 2)
	ProjectSettings.set("display/window/handheld/orientation", 6)
	ProjectSettings.set("display/window/vsync/vsync_mode", 0)
	ProjectSettings.set("gui/theme/base_color", Color(0.0793, 0.10296, 0.13, 1))
	ProjectSettings.set("gui/theme/accent_color", Color(0.2075, 0.581, 0.83, 1))
	ProjectSettings.set("gui/theme/padding", 0)
	ProjectSettings.set("gui/theme/border_width", 4)
	ProjectSettings.set("gui/theme/corner_radius", 16)
	ProjectSettings.set("gui/theme/font_size", 32)
	ProjectSettings.set("gui/theme/custom_font", "res://addons/blazium_theme_editor/fonts/NotoSans-Regular.ttf")
	ProjectSettings.set("gui/theme/default_font_antialiasing", 2)
	ProjectSettings.set("gui/theme/default_font_multichannel_signed_distance_field", true)
	ProjectSettings.set("gui/theme/custom", "uid://c8qig4a3cme6e")
	ProjectSettings.set("input_devices/pointing/emulate_touch_from_mouse", true)
	var languages = []
	# Add addon languages
	for file in DirAccess.get_files_at("res://addons/blazium_shared_menus/lang"):
		if file.ends_with("po"):
			languages.append("res://addons/blazium_shared_menus/lang/" + file)
	# Add project languages
	if DirAccess.dir_exists_absolute("res://lang"):
		for file in DirAccess.get_files_at("res://lang"):
			if file.ends_with("po"):
				languages.append("res://lang/" + file)
	ProjectSettings.set("internationalization/locale/translations", PackedStringArray(languages))
	ProjectSettings.set("rendering/renderer/rendering_method", "gl_compatibility")
	ProjectSettings.set("rendering/renderer/rendering_method.mobile", "gl_compatibility")
	ProjectSettings.set("rendering/textures/vram_compression/import_etc2_astc", true)
	ProjectSettings.set("display/window/handheld/orientation", DisplayServer.ScreenOrientation.SCREEN_SENSOR)
	ProjectSettings.set("display/window/vsync/vsync_mode", DisplayServer.VSyncMode.VSYNC_DISABLED)
	if ProjectSettings.get("application/config/version") == "":
		ProjectSettings.set("application/config/version", "1.0.0")
	ProjectSettings.set("application/run/main_scene", "res://addons/blazium_shared_menus/main_menu/main_menu.tscn")

func set_default_setting(setting_name: String, description: String, value: Variant):
	if !ProjectSettings.has_setting(setting_name):
		print("Creating Setting " + setting_name + "." +  description)
		ProjectSettings.set(setting_name, value)

func _exit_tree() -> void:
	remove_autoload_singleton.call_deferred("SettingsAutoload")
	remove_autoload_singleton.call_deferred("GlobalLobbyClient")
	remove_autoload_singleton.call_deferred("WordFilterAutoload")
	
