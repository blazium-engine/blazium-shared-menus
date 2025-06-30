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
	
	add_autoload_singleton.call_deferred("SettingsAutoload", "res://addons/blazium_shared_menus/settings/settings_autoload.gd")
	add_autoload_singleton.call_deferred("CosmeticAutoload", "res://addons/blazium_shared_menus/services/cosmetic_autoload.gd")
	add_autoload_singleton.call_deferred("GlobalLobbyClient", "res://addons/blazium_shared_menus/services/lobby_client.tscn")
	add_autoload_singleton.call_deferred("WordFilterAutoload", "res://addons/blazium_shared_menus/settings/word_filter_autoload.gd")

func set_default_setting(setting_name: String, description: String, value: Variant):
	if !ProjectSettings.has_setting(setting_name):
		print("Creating Setting " + setting_name + "." +  description)
		ProjectSettings.set(setting_name, value)

func _exit_tree() -> void:
	remove_autoload_singleton.call_deferred("SettingsAutoload")
	remove_autoload_singleton.call_deferred("CosmeticAutoload")
	remove_autoload_singleton.call_deferred("GlobalLobbyClient")
	remove_autoload_singleton.call_deferred("WordFilterAutoload")
	
