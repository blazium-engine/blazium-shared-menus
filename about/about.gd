@tool
extends BlaziumPanel

@export var back_button: Button
@export var click_sound: AudioStreamPlayer
var main_menu_scene: PackedScene = load("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")

@export var rich_text_label: RichTextLabel

@export var left_spacer: Control
@export var right_spacer: Control

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	resized.connect(_on_resized)
	_on_resized()
	back_button.grab_focus()
	rich_text_label.text = tr("credits").format({version = ProjectSettings.get("application/config/version")})

func _shortcut_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	if is_inside_tree():
		await get_tree().process_frame
	if is_inside_tree():
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	GlobalLobbyClient.open_url(meta)

func _on_resized() -> void:
	var show_spacers = GlobalLobbyClient.ui_breakpoint()
	left_spacer.visible = !show_spacers
	right_spacer.visible = !show_spacers


func _on_discord_pressed() -> void:
	GlobalLobbyClient.open_url("https://discord.gg/B5ArWYX3Hr")
