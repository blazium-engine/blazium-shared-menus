extends BlaziumControl

@export var click_sfx: AudioStreamPlayer
@export var player_list: HBoxContainer
var user_element_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/container_peer.tscn")

var peer_to_kick: String
var kick_popup: CustomDialog

func _ready() -> void:
	GlobalLobbyClient.peer_joined.connect(_peer_joined)
	GlobalLobbyClient.peer_left.connect(_peer_left)
	load_peers(GlobalLobbyClient.peers)

	kick_popup = CustomDialog.new("lobby_prompt_kick_player")
	kick_popup.name = "KickPopup"
	kick_popup.cancelled.connect(_on_kick_popup_cancelled)
	kick_popup.confirmed.connect(_on_kick_popup_confirm)
	kick_popup.hide()
	get_tree().current_scene.add_child.call_deferred(kick_popup, false, Node.INTERNAL_MODE_BACK)

func _on_kick_popup_cancelled() -> void:
	click_sfx.play()
	_restore_last_focus()


func _on_kick_popup_confirm() -> void:
	click_sfx.play()
	await GlobalLobbyClient.kick_peer(peer_to_kick).finished
	_restore_last_focus()

func kick_peer(peer: LobbyPeer) -> void:
	if peer.id == GlobalLobbyClient.peer.id:
		return
	peer_to_kick = peer.id
	kick_popup.text = tr("lobby_prompt_kick_player").format({player = peer.user_data.get("name", "")})
	_update_last_focus()
	kick_popup.show()

func _peer_joined(_peer: LobbyPeer):
	load_peers(GlobalLobbyClient.peers)


func _peer_left(_peer: LobbyPeer, _kicked: bool):
	load_peers(GlobalLobbyClient.peers)


func load_peers(peers: Array[LobbyPeer]):
	for child in player_list.get_children():
		child.queue_free()
	for peer in peers:
		var user_node := user_element_scene.instantiate()
		user_node.selected = GlobalLobbyClient.peer.id == peer.id
		user_node.enable_ready = false
		user_node.peer = peer
		user_node.kick.connect(kick_peer)
		player_list.add_child(user_node)
