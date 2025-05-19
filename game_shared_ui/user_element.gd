extends PanelContainer

signal kick(peer_id: String)

@export var label: Label
@export var avatar: Avatar
@export var kick_button: Button
@export var disconnected_icon: TextureRect
@export var click_sound: AudioStreamPlayer

var peer_info: LobbyPeer

@onready var platform: Avatar = $HBoxContainer/Avatar/Platform


func _ready() -> void:
	kick_button.visible = GlobalLobbyClient.is_host() and peer_info.id != GlobalLobbyClient.peer.id
	disconnected_icon.visible = peer_info.disconnected
	GlobalLobbyClient.received_lobby_data.connect(_received_lobby_data)
	GlobalLobbyClient.peer_disconnected.connect(_peer_disconnected)
	GlobalLobbyClient.peer_reconnected.connect(_peer_reconnected)
	label.text = peer_info.user_data.get("name", "")
	avatar.frame = peer_info.user_data.get("avatar", 0)
	match peer_info.platform:
		"discord": platform.frame = 0
		"steam": platform.frame = 1
		"anon": platform.frame = 2
	_received_lobby_data(GlobalLobbyClient.lobby.data)


func _peer_disconnected(peer: LobbyPeer):
	if peer.id == peer_info.id:
		disconnected_icon.show()


func _peer_reconnected(peer: LobbyPeer):
	if peer.id == peer_info.id:
		disconnected_icon.hide()


func _received_lobby_data(data: Dictionary):
	# Host's turn
	if data["game_state"] == "started":
		if data.get("dealer", "") == peer_info.id:
			theme_type_variation = "SelectedPanel"
		else:
			theme_type_variation = ""
	elif data["game_state"] == "playing":
	# Peers turn
		if data.get("dealer", "") != peer_info.id:
			theme_type_variation = "SelectedPanel"
		else:
			theme_type_variation = ""


func _on_kick_button_pressed() -> void:
	click_sound.play()
	kick.emit(peer_info)
