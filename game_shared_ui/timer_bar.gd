class_name TimerBar
extends Control

@export var progress_bar: TextureRect
@export var progress_label: Label
@export var total_time: float = 7.0

var progress_material: ShaderMaterial
var progress: float = 1.0
var progress_seconds: int = 0
var last_seconds: int = -1
var normal_font_size: int = 220
var enlarged_font_size: int = 300
var critical_font_size: int = 370
var color_tween: Tween
var server_time = 0
var is_finished: bool = false 

func _ready() -> void:
	progress_material = progress_bar.material as ShaderMaterial
	update_visuals(7)
	server_time = int(GlobalLobbyClient.lobby.data.get("turn_timestamp", 0))

func set_server_time(time) -> void:
	server_time = int(time)
	is_finished = false
	
func _process(_delta: float) -> void:
	var current_time = Time.get_unix_time_from_system() * 1000
	progress = (current_time - server_time) / 1000
	if progress > 0:
		progress /= total_time
	else:
		progress = 0
	if progress > 1:
		progress = 1
	
	if progress >= 1:
		progress_seconds = 0
		if not is_finished:
			is_finished = true
	else:
		progress_seconds = int((1 - progress) * total_time) + 1
	
	if progress_seconds != last_seconds:
		update_visuals(progress_seconds)
		last_seconds = progress_seconds
	
	progress_material.set_shader_parameter("value", 1 - progress)
	progress_label.text = str(progress_seconds)

func update_visuals(seconds: int) -> void:
	if color_tween:
		color_tween.kill()
	
	var font_tween = create_tween()
	if seconds > 3:
		font_tween.tween_property(progress_label, "theme_override_font_sizes/font_size", enlarged_font_size, 0.25)
		font_tween.tween_property(progress_label, "theme_override_font_sizes/font_size", normal_font_size, 0.25)
		color_tween = create_tween().set_loops()
		color_tween.tween_property(progress_label, "modulate", Color("#78389e"), 0.5) # Purple
		color_tween.tween_property(progress_label, "modulate", Color("#ffffff"), 0.5) # White
	else:
		font_tween.tween_property(progress_label, "theme_override_font_sizes/font_size", critical_font_size, 0.3)
		font_tween.tween_property(progress_label, "theme_override_font_sizes/font_size", normal_font_size, 0.3)
		color_tween = create_tween().set_loops()
		color_tween.tween_property(progress_label, "modulate", Color("#a70000"), 0.5) # Dark red
		color_tween.tween_property(progress_label, "modulate", Color("#ffffff"), 0.5) # White
