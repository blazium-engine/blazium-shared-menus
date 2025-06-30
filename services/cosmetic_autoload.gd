extends Node


var character_cosmetics := CharacterCosmetics.new()


func _ready() -> void:
	character_cosmetics.load_from_config(SettingsAutoload.config, "Cosmetics")
	GlobalLobbyClient.connected_to_server.connect(_connected_to_server)
	_connected_to_server(null, "")

func _connected_to_server(_peer: LobbyPeer, _reconnection_token: String):
	character_cosmetics.apply_to_user_data()

func save_to_config():
	character_cosmetics.save_to_config(SettingsAutoload.config, "Cosmetics")
