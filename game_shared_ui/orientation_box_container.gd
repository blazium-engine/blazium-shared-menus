extends BoxContainer


func _ready():
	_size_changed()
	get_tree().root.size_changed.connect(_size_changed)


func _size_changed():
	if get_viewport().get_window() == null:
		return
	var window_size := Vector2(get_viewport().get_window().size)
	var scale_factor: float = window_size.y / window_size.x
	if scale_factor < 0.0:
		scale_factor = 1.0
	vertical = scale_factor > 1.05
