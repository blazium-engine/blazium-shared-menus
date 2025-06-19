@tool
class_name CustomOptionButton
extends OptionButton

@export var press_timeout: float = 0.25
var hover_scale: float = 1.05
var press_scale: float = 0.95
var anim_time: float = 0.1

@export var user_icon: String:
	set(value):
		user_icon = value
		_update()

var tween: Tween

func _ready():
	if Engine.is_editor_hint():
		return
	_resized()
	_scale_changed()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ThemeDB.scale_changed.connect(_scale_changed)
	_scale_changed.call_deferred()
	ThemeDB.icons_changed.connect(_update)
	pressed.connect(_pressed_timeout)
	resized.connect(_resized)
	
	# Connect signals for hover and focus
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_mouse_entered)
	focus_exited.connect(_on_mouse_exited)

func _resized():
	set_pivot_offset(size * 0.5)

func _scale_changed():
	custom_minimum_size.x = 100 * GlobalLobbyClient.get_theme_scale().x
	custom_minimum_size.y = 100 * GlobalLobbyClient.get_theme_scale().x

func _pressed_timeout():
	disabled = true
	_play_press_animation()
	await get_tree().create_timer(press_timeout).timeout
	disabled = false

func _update():
	if user_icon.is_empty():
		icon = null
		return
	if ThemeDB.has_user_icon(user_icon):
		icon = ThemeDB.get_user_icon(user_icon)
	elif ThemeDB.has_icon(user_icon):
		icon = ThemeDB.get_icon(user_icon)
	else:
		icon = null

func _validate_property(property: Dictionary) -> void:
	if property["name"] == "icon":
		property["usage"] = PROPERTY_USAGE_NONE

func _on_mouse_entered():
	_animate_scale(hover_scale)

func _on_mouse_exited():
	_animate_scale(1.0)

func _play_press_animation():
	_animate_scale(press_scale)
	await get_tree().create_timer(anim_time).timeout
	_animate_scale(hover_scale if get_rect().has_point(get_local_mouse_position()) else 1.0)

func _animate_scale(target_scale: float):
	if tween:
		tween.kill()
	scale = Vector2.ONE
	tween = create_tween()
	
	if target_scale != 1.0:
		tween.tween_property(self, "scale", Vector2(target_scale + 0.1, target_scale + 0.1), anim_time/2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), anim_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
