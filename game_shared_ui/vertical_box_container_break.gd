extends BoxContainer

func _ready():
	_size_changed()
	get_tree().root.size_changed.connect(_size_changed)


func _size_changed():
	vertical = GlobalLobbyClient.ui_breakpoint()
