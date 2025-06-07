extends TextureRect

const MAX_RIPPLES = 100
var click_positions := []
var click_times := []
@export var sound: AudioStreamPlayer
@export var panel: TextureRect
@export var texture_rect: TextureRect
@export var audio_stream: AudioStream

func _ready():
	ThemeDB.font_color_changed.connect(_select_colors)
	_select_colors()
	click_positions.resize(MAX_RIPPLES)
	click_times.resize(MAX_RIPPLES)
	for i in MAX_RIPPLES:
		click_positions[i] = Vector2(-1000, -1000) # Offscreen
		click_times[i] = 0.0
	update_shader_params()

func _select_colors():
	var color = ThemeDB.get_default_theme().get_color("font_color", "Colors")
	var alpha = 0.1 if color.get_luminance() > 0.5 else 0.1
	# Dark mode
	if color.r > 0.5:
		material.set_shader_parameter("hint_color", Color("1f252dAb"))
		panel.self_modulate = Color("151a20")
		texture_rect.self_modulate = Color("151a20")
	else:
		material.set_shader_parameter("hint_color", Color("80868e6f"))
		panel.self_modulate = Color("A1A1A1")
		texture_rect.self_modulate = Color("A1A1A1")

func _process(delta):
	for i in MAX_RIPPLES:
		if click_times[i] > 0.0:
			click_times[i] += delta
			if click_times[i] > material.get_shader_parameter("max_duration"):
				click_times[i] = 0.0
				click_positions[i] = Vector2(-1000, -1000)
	update_shader_params()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var local_pos = get_local_mouse_position()
		add_ripple(local_pos)

func add_ripple(pos: Vector2):
	if !sound.playing:
		sound.play()
	var playback = sound.get_stream_playback()
	playback.play_stream(audio_stream)
	
	for i in MAX_RIPPLES:
		if click_times[i] <= 0.0:
			click_positions[i] = pos
			click_times[i] = 0.001 # Small value to activate
			update_shader_params()
			return
	
	# If all slots full, replace oldest
	var oldest_index = 0
	var oldest_time = click_times[0]
	for i in range(1, MAX_RIPPLES):
		if click_times[i] < oldest_time:
			oldest_index = i
			oldest_time = click_times[i]
	click_positions[oldest_index] = pos
	click_times[oldest_index] = 0.001
	update_shader_params()

func update_shader_params():
	material.set_shader_parameter("click_positions", click_positions)
	material.set_shader_parameter("click_times", click_times)
