extends Control

signal kick(peer_id: String)

@export var disconnected_texture: TextureRect
@export var bg_color: Color
@export var peer: LobbyPeer
@export var logs: Label
@export var ready_msg: String = "Ready"
@export var not_ready_msg: String = "Not Ready"
@export var click_sound: AudioStreamPlayer

var avatar: int = 0
var platform: String = "anon"
var selected: bool

@onready var _peer_name: Label = $HBoxContainer/VBoxContainer/Label
@onready var _peer_platform: Avatar = $HBoxContainer/Avatar/Platform
@onready var _peer_avatar: Avatar = $HBoxContainer/Avatar
@onready var _peer_ready: Label = $HBoxContainer/VBoxContainer/Ready
@onready var _kick_button: Button = $HBoxContainer/Button


func _ready():
	if selected:
		theme_type_variation = "SelectedPanel"
	disconnected_texture.visible = peer.disconnected
	GlobalLobbyClient.peer_ready.connect(_on_peer_ready)
	GlobalLobbyClient.peer_disconnected.connect(_peer_disconnected)
	GlobalLobbyClient.peer_reconnected.connect(_peer_reconnected)
	_peer_name.text = peer.user_data.get("name", "")
	_peer_ready.text = ready_msg if peer.ready else not_ready_msg
	_peer_avatar.frame = avatar
	match platform:
		"discord":
			_peer_platform.frame = 0
		"steam":
			_peer_platform.frame = 1
		"anon":
			_peer_platform.frame = 2
	_kick_button.visible = GlobalLobbyClient.is_host() and peer.id != GlobalLobbyClient.peer.id


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
		_peer_ready.text = ready_msg if peer.ready else not_ready_msg
