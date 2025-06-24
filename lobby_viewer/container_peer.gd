extends Control

signal kick(peer_id: String)

@export var disconnected_texture: TextureRect
@export var bg_color: Color
@export var peer: LobbyPeer
@export var click_sound: AudioStreamPlayer

var avatar: int = 0
var platform: String = "anon"
var selected: bool

@onready var _peer_name: Label = $HBoxContainer/VBoxContainer/Label
@onready var _peer_platform: Avatar = $HBoxContainer/Avatar/Platform
@onready var _peer_avatar: Avatar = $HBoxContainer/Avatar
@onready var _peer_ready: CustomTextureRect = $HBoxContainer/TextureRect2
@onready var _kick_button: Button = $HBoxContainer/Button


func _ready():
	if selected:
		theme_type_variation = "SelectedPanel"
	disconnected_texture.visible = peer.disconnected
	GlobalLobbyClient.peer_ready.connect(_on_peer_ready)
	GlobalLobbyClient.peer_disconnected.connect(_peer_disconnected)
	GlobalLobbyClient.peer_reconnected.connect(_peer_reconnected)
	ThemeDB.scale_changed.connect(_resized)
	_resized()
	var user_name = peer.user_data.get("name", "")
	_peer_name.text = WordFilterAutoload.filter_message(user_name)
	_peer_ready.user_icon = "check" if peer.ready else "hourglass_bottom"
	_peer_avatar.frame = avatar
	match platform:
		"discord":
			_peer_platform.frame = 0
		"steam":
			_peer_platform.frame = 1
		"anon":
			_peer_platform.frame = 2
	_kick_button.visible = GlobalLobbyClient.is_host() and peer.id != GlobalLobbyClient.peer.id

func _resized():
	_peer_platform.texture_scale = GlobalLobbyClient.get_theme_scale().x * 0.7
	_peer_avatar.texture_scale = GlobalLobbyClient.get_theme_scale().x

func _peer_disconnected(peer_event: LobbyPeer):
	if peer.id == peer_event.id:
		disconnected_texture.show()


func _peer_reconnected(peer_event: LobbyPeer):
	if peer.id == peer_event.id:
		disconnected_texture.hide()


func _on_button_pressed() -> void:
	click_sound.play()
	kick.emit(peer)


func _on_peer_ready(updated_peer: LobbyPeer, _p_ready: bool):
	if updated_peer.id == peer.id:
		_peer_ready.user_icon = "check" if peer.ready else "hourglass_bottom"
