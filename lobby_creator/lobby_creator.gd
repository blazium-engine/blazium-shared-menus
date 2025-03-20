@tool
extends BlaziumPanel

@export var password_line_edit: LineEdit
@export var logs: Label
@export var max_players_label: Label
@export var title_label: LineEdit
@export var create_button: Button
@export var left_spacer: Control
@export var right_spacer: Control
@export var increment_button: Button
@export var decrement_button: Button
@export var sealed_checkbox: CheckBox
@export var max_points_line_edit: LineEdit
@export var click_sound: AudioStreamPlayer

var main_menu_scene: PackedScene = load("res://menus/main_menu/main_menu.tscn")
var lobby_viewer_scene: PackedScene = load("res://menus/lobby_viewer/lobby_viewer.tscn")

var sealed := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	GlobalLobbyClient.disconnected_from_server.connect(_disconnected_from_server)
	if not (OS.get_name() in ["Android", "iOS"]):
		title_label.grab_focus()


func _on_button_create_lobby_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if title_label.text.is_empty():
		title_label.text = "WordGame" + str(randi() % 1000)
	var max_points = max_points_line_edit.text
	if max_points == "":
		max_points = 0
	var result: ViewLobbyResult = await GlobalLobbyClient.create_lobby(title_label.text, sealed, { "max_points": int(max_points_line_edit.text) }, int(max_players_label.text), password_line_edit.text).finished

	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	if not result.has_error():
		if is_inside_tree():
			get_tree().change_scene_to_packed(lobby_viewer_scene)


func _on_button_increment_pressed() -> void:
	click_sound.play()
	var players := int(max_players_label.text)
	players += 1
	if players > 10:
		players = 10
	max_players_label.text = str(players)
	_update_max_players_buttons(players)


func _on_button_decrement_pressed() -> void:
	click_sound.play()
	var players := int(max_players_label.text)
	players -= 1
	if players < 2:
		players = 2
	max_players_label.text = str(players)
	_update_max_players_buttons(players)


func _update_max_players_buttons(players):
	decrement_button.disabled = players == 2
	increment_button.disabled = players == 10


func _on_title_text_submitted(_new_text: String) -> void:
	_on_button_create_lobby_pressed()


func _on_resized() -> void:
	var show_spacers = size.x > 600
	left_spacer.visible = show_spacers
	right_spacer.visible = show_spacers


func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()


func _disconnected_from_server(_reason: String):
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_sealed_toggled(toggled_on: bool) -> void:
	click_sound.play()
	sealed_checkbox.text = "Yes" if toggled_on else "No"
	sealed = toggled_on


func _on_back_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)
