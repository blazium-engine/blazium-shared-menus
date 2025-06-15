extends BoxContainer

@export var breakpoint_1024:= true
@export var breakpoint_768:= false
@export var breakpoint_400:= false

func _ready():
	_size_changed()
	get_tree().root.size_changed.connect(_size_changed)


func _size_changed():
	if breakpoint_400:
		vertical = GlobalLobbyClient.breakpoint_400()
	if breakpoint_768:
		vertical = GlobalLobbyClient.breakpoint_768()
	if breakpoint_1024:
		vertical = GlobalLobbyClient.breakpoint_1024()
