@tool
extends Panel


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	mouse_force_pass_scroll_events = false
	z_as_relative = false
	z_index = 4096
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.2)
	add_theme_stylebox_override("panel", style)
