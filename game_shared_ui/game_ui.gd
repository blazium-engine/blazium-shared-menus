class_name GameUI
extends BlaziumControl

@export var chat: ChatContainer

@export var back_button: Button

@export_group("Sounds")
@export var click_sfx: AudioStreamPlayer
@export var game_start_sfx: AudioStreamPlayer

var loading_scene: PackedScene = load("res://addons/blazium_shared_menus/loading_screen/loading_screen.tscn")
var main_menu_scene: PackedScene = load("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")

var state_was_started: bool = false
var exit_popup: CustomDialog


func _ready() -> void:
	game_start_sfx.play()

	GlobalLobbyClient.lobby_left.connect(_lobby_left)
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)

	exit_popup = CustomDialog.new("menu_prompt_exit")
	exit_popup.name = "ExitPopup"
	exit_popup.cancelled.connect(_on_exit_popup_cancelled)
	exit_popup.confirmed.connect(_on_exit_popup_confirmed)
	exit_popup.hide()
	get_tree().current_scene.add_child.call_deferred(exit_popup, false, Node.INTERNAL_MODE_BACK)

	_set_fallback_focus(chat.chat_text)

func _lobby_left(_kicked: bool):
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func leave_lobby():
	await GlobalLobbyClient.leave_lobby().finished



func _disconnected_from_server(_reason: String):
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(loading_scene)


func _on_back_pressed() -> void:
	click_sfx.play()
	exit_popup.show()
	exit_popup.cancel_button.grab_focus()


func _physics_process(delta: float) -> void:
	# Checking this in inpus results in it being ran much more often than needed.
	if Input.is_action_just_pressed("ui_cancel"):
		if exit_popup.visible:
			exit_popup.visible = false
			_on_exit_popup_cancelled()
		else:
			exit_popup.show()
			exit_popup.cancel_button.grab_focus()


func _on_exit_popup_cancelled() -> void:
	click_sfx.play()
	back_button.grab_focus()


func _on_exit_popup_confirmed() -> void:
	click_sfx.play()
	leave_lobby()


func _play_click_sound() -> void:
	click_sfx.play()



func send_chat(peer_id: LobbyPeer, message: String):
	chat.append_message_to_chat(peer_id, message)
