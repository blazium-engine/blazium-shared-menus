extends HBoxContainer

@export var prev_avatar: Avatar
@export var cur_avatar: Avatar
@export var next_avatar: Avatar

func _ready() -> void:
	ThemeDB.scale_changed.connect(_scale_changed)
	_scale_changed.call_deferred()

func _scale_changed():
	prev_avatar.texture_scale = GlobalLobbyClient.get_theme_scale().x * 0.7
	cur_avatar.texture_scale = GlobalLobbyClient.get_theme_scale().x
	next_avatar.texture_scale = GlobalLobbyClient.get_theme_scale().x * 0.7
