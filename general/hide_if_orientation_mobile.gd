extends Control

func _ready():
	_size_changed()
	get_tree().root.size_changed.connect(_size_changed)


func _size_changed():
	if get_viewport().get_window() == null:
		return
	visible = !GlobalLobbyClient.ui_breakpoint()
