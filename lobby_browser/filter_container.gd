extends FoldableContainer

@export var expand_focus_target: Control

func _ready() -> void:
	folding_changed.connect(_on_folding_changed)

func _on_folding_changed(expanded: bool) -> void:
	if not expanded:
		expand_focus_target.grab_focus()
