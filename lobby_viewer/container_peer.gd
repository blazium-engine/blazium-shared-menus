class_name ContainerPeer
extends Control

signal kick(peer_id: String)

@export var disconnected_texture: TextureRect
@export var bg_color: Color
@export var click_sound: AudioStreamPlayer
@export var host_texture: TextureRect

var peer: LobbyPeer
var enable_ready:bool
var selected: bool

@onready var _peer_name: Label = $HBoxContainer/PeerName
@onready var _peer_points: Label = $HBoxContainer/PeerPoints
@onready var _peer_platform: Avatar = $HBoxContainer/Avatar/Platform
@onready var _peer_avatar: Avatar = $HBoxContainer/Avatar
@onready var _peer_ready: CustomTextureRect = $HBoxContainer/Ready
@onready var _kick_button: Button = $HBoxContainer/Button


func _ready():
	if selected:
		theme_type_variation = "SelectedPanel"
	if !enable_ready:
		_peer_ready.hide()
	disconnected_texture.visible = peer.disconnected
	GlobalLobbyClient.peer_ready.connect(_on_peer_ready)
	GlobalLobbyClient.peer_disconnected.connect(_peer_disconnected)
	GlobalLobbyClient.peer_reconnected.connect(_peer_reconnected)
	GlobalLobbyClient.lobby_hosted.connect(_lobby_hosted)
	GlobalLobbyClient.received_peer_data.connect(_received_peer_data)
	for host in GlobalLobbyClient.peers:
		if host.id == GlobalLobbyClient.lobby.host:
			_lobby_hosted(host)
	ThemeDB.scale_changed.connect(_resized)
	_resized()
	var user_name = peer.user_data.get("name", "")
	_peer_name.text = WordFilterAutoload.filter_message(user_name)
	_update_peer_score()
	_on_peer_ready(peer, peer.ready)
	_peer_avatar.frame = peer.user_data.get("avatar", 0)
	match peer.platform:
		"discord":
			_peer_platform.frame = 0
		"steam":
			_peer_platform.frame = 1
		"anon":
			_peer_platform.frame = 2

func _received_peer_data(data: Dictionary, to_peer: LobbyPeer, is_private: bool):
	if to_peer.id == peer.id:
		_update_peer_score()

func _update_peer_score():
	_peer_points.text = str(int(peer.data.get("total_points", "")))
	if _peer_points.text == "0":
		_peer_points.text = ""

func _lobby_hosted(host: LobbyPeer):
	host_texture.visible = peer.id == host.id
	# Cannot kick yourself
	if peer.id != GlobalLobbyClient.peer.id:
		_kick_button.visible = GlobalLobbyClient.peer.id == host.id 

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
	if updated_peer.id != peer.id:
		return
	if peer.ready:
		_peer_ready.user_icon = "check"
		_peer_ready.modulate = "6bff7f"
	else:
		_peer_ready.user_icon = "hourglass_bottom"
		_peer_ready.modulate = "ffff6a"
