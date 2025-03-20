@tool
extends BlaziumPanel

@export var click_sound: AudioStreamPlayer
var main_menu_scene: PackedScene = load("res://addons/blazium_shared_menus/main_menu/main_menu.tscn")


func _shortcut_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_packed(main_menu_scene)
