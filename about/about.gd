@tool
extends BlaziumPanel

@export var back_button: Button
@export var click_sound: AudioStreamPlayer
var main_menu_scene: PackedScene = load(ProjectSettings.get_setting("blazium/game/main_scene", "res://addons/blazium_shared_menus/main_menu/main_menu.tscn"))

@onready var rich_text_label: RichTextLabel = $HBoxContainer/PanelContainer/VBoxContainer/RichTextLabel
@onready var credits: GameCredits = $Credits

func _ready() -> void:
	back_button.grab_focus()
	rich_text_label.text = credits.CREDITS

func _shortcut_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_packed(main_menu_scene)


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
