class_name TimerBar
extends Control

@export var progress_bar: TextureRect
@export var progress_label: Label

var progress_material: ShaderMaterial
var progress: float = 1.0
@export var total_time: float = 7.0

func _ready() -> void:
	progress_material = progress_bar.material as ShaderMaterial

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
	progress_material.set_shader_parameter("value", 1 - progress)
	progress_label.text = str(int((1 - progress) * total_time) + 1)
