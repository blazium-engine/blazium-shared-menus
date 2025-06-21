extends Control

@export var _lobby_name: Label
@export var _lobby_players: Label
@export var _join_button: CustomButton
@export var click_sound: AudioStreamPlayer

var lobby_viewer_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/lobby_viewer.tscn")
var password_popup: CustomDialog
var lobby_full_popup: CustomDialog
var lobby: LobbyInfo


func _ready():
	_lobby_name.text = lobby.lobby_name
	_lobby_players.text = str(lobby.players) + "/" + str(lobby.max_players)
	if lobby.sealed:
		_join_button.user_icon = "refresh"
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

	if not result.has_error():
		await get_tree().process_frame
		if is_inside_tree():
			get_tree().change_scene_to_packed(lobby_viewer_scene)
	elif result.error == "Lobby is full":
		lobby_full_popup.show()
