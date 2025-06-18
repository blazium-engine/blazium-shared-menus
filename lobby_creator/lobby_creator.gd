@tool
extends BlaziumPanel

@export var password_line_edit: LineEdit
@export var max_players_label: Label
@export var title_label: LineEdit
@export var create_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var increment_button: Button
@export var decrement_button: Button
@export var sealed_checkbox: CheckButton
@export var click_sound: AudioStreamPlayer
@export var settings_vbox: VBoxContainer

var loading_scene: PackedScene = load("res://game/loading_screen.tscn")
var main_menu_scene: PackedScene = load(ProjectSettings.get_setting("blazium/game/main_scene", "res://addons/blazium_shared_menus/main_menu/main_menu.tscn"))
var lobby_viewer_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_viewer/lobby_viewer.tscn")
var tag_setting_scene: PackedScene = load("res://addons/blazium_shared_menus/lobby_creator/tag_setting.tscn")

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	title_label.grab_focus()
	max_players_label.text = tr("players_max").format({players = ProjectSettings.get_setting("blazium/game/max_players_default", 10)})
	_update_max_players_buttons(int(max_players_label.text))

func _on_button_create_lobby_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if title_label.text.is_empty():
		title_label.text = "Game" + str(randi() % 1000)
	var tags = {}
	var config = ConfigFile.new()
	config.load("user://blazium.cfg")
	var game_mode = "normal_mode"
	tags["game_mode"] = game_mode
	var result: ViewLobbyResult = await GlobalLobbyClient.create_lobby(title_label.text, sealed_checkbox.button_pressed, tags, int(max_players_label.text), password_line_edit.text).finished

	if not result.has_error():
		await get_tree().process_frame
		if is_inside_tree():
			get_tree().change_scene_to_packed(lobby_viewer_scene)


func _on_button_increment_pressed() -> void:
	click_sound.play()
	var player_limit := int(max_players_label.text)
	player_limit += 1
	var max_players = ProjectSettings.get_setting("blazium/game/max_players_max", 10)
	if player_limit > max_players:
		player_limit = max_players
	max_players_label.text = tr("players_max").format({players = player_limit})
	_update_max_players_buttons(player_limit)


func _on_button_decrement_pressed() -> void:
	click_sound.play()
	var player_limit := int(max_players_label.text)
	player_limit -= 1
	var min_players = ProjectSettings.get_setting("blazium/game/max_players_min", 2)
	if player_limit < min_players:
		player_limit = min_players
	max_players_label.text = tr("players_max").format({players = player_limit})
	_update_max_players_buttons(player_limit)


func _update_max_players_buttons(players):
	decrement_button.disabled = players == ProjectSettings.get_setting("blazium/game/max_players_min", 2)
	increment_button.disabled = players == ProjectSettings.get_setting("blazium/game/max_players_max", 10)


func _on_title_text_submitted(_new_text: String) -> void:
	_on_button_create_lobby_pressed()


func _on_resized() -> void:
	var show_spacers = GlobalLobbyClient.breakpoint_1024()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers


func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()


func _disconnected_from_server(_reason: String):
	if is_inside_tree():
		await get_tree().process_frame
		if is_inside_tree():
			get_tree().change_scene_to_packed(loading_scene)


func _on_sealed_toggled(toggled_on: bool) -> void:
	click_sound.play()
	sealed_checkbox.text = "hidden_yes" if toggled_on else "hidden_no"


func _on_back_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)
