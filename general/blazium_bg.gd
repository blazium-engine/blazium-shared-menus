extends TextureRect

@export var background: TextureRect
@export var vignette: TextureRect

func _ready():
	ThemeDB.font_color_changed.connect(_select_colors)
	_select_colors()

func _select_colors():
	var color = ThemeDB.get_default_theme().get_color("font_color", "Colors")
	# Dark mode
	var modulate_color: Color
	if color.r > 0.5:
		material.set_shader_parameter("hint_color", Color("1f252dAb"))
		modulate_color = Color("151a20")
	else:
		material.set_shader_parameter("hint_color", Color("80868e6f"))
		modulate_color = Color("A1A1A1")

	background.self_modulate = modulate_color
	vignette.self_modulate = modulate_color
