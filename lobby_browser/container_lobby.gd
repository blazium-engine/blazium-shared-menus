extends Control

@export var _lobby_name: Label
@export var _lobby_players: Label
@export var _join_button: CustomButton
@export var click_sound: AudioStreamPlayer

var lobby_viewer_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/lobby_viewer.tscn")
var password_popup: CustomDialog
var lobby: LobbyInfo
var logs: Label


func _ready():
	_lobby_name.text = lobby.lobby_name
	_lobby_players.text = tr("lobby_player_count").format({
		players = lobby.players,
		max_players = lobby.max_players
	})
	if lobby.sealed:
		_join_button.text = "lobby_reconnect"
	if lobby.password_protected:
		_join_button.user_icon = "lock"


func _on_button_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if lobby.password_protected:
		password_popup.set_meta("lobby_id", lobby.id)
		password_popup.show()
		return

	var result: ViewLobbyResult = await GlobalLobbyClient.join_lobby(lobby.id).finished

	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	if not result.has_error():
		if is_inside_tree():
			get_tree().change_scene_to_packed(lobby_viewer_scene)
