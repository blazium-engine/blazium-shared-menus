extends Node

signal code_entered

@export var input_code: Array[Key] = [
	KEY_UP, KEY_UP,
	KEY_DOWN, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT,
	KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A
]

var sequence: int = 0


func _shortcut_input(event: InputEvent) -> void:
	# Ignore echos and initial press. Release is what we want.
	if event.is_echo() or not event.is_released():
		return
	if input_code.size() == 0:
		return
	if event.key_label == input_code[sequence]:
		sequence += 1
	else:
		sequence = 0
	if sequence >= input_code.size():
		sequence = 0
		code_entered.emit()
