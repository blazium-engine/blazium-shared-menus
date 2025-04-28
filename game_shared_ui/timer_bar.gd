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
var color_tween: Tween

func _ready() -> void:
	progress_material = progress_bar.material as ShaderMaterial

	update_visuals(0)

func _process(_delta: float) -> void:
	var current_time = Time.get_unix_time_from_system() * 1000
	var server_time = int(GlobalLobbyClient.lobby.data.get("turn_timestamp", 0))
	progress = (current_time - server_time) / 1000
	if progress > 0:
		progress /= total_time
	else:
		progress = 0
	if progress > 1:
		progress = 1
	progress_seconds = int((1 - progress) * total_time) + 1
	
	if progress_seconds != last_seconds:
		update_visuals(progress_seconds)
		last_seconds = progress_seconds
	
	progress_material.set_shader_parameter("value", 1 - progress)
	progress_label.text = str(progress_seconds)

func update_visuals(seconds: int) -> void:
	var font_tween = create_tween()
	font_tween.tween_property(progress_label, "theme_override_font_sizes/font_size", enlarged_font_size, 0.25)
	font_tween.tween_property(progress_label, "theme_override_font_sizes/font_size", normal_font_size, 0.25)
	
	if color_tween:
		color_tween.kill()
	
	color_tween = create_tween().set_loops()
	if seconds > 3:
		color_tween.tween_property(progress_label, "modulate", Color("#78389e"), 0.5) # Purple
		color_tween.tween_property(progress_label, "modulate", Color("#ffffff"), 0.5) # White
	else:
		color_tween.tween_property(progress_label, "modulate", Color("#a70000"), 0.5) # Dark red
		color_tween.tween_property(progress_label, "modulate", Color("#ffffff"), 0.5) # White
