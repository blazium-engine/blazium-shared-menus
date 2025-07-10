@tool
extends CustomOptionButton

var tags: Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for tag in ProjectSettings.get_setting("blazium/game/lobby_modes"):
		tags.push_back(str(tag))
	for idx in range(tags.size()):
		match idx:
			0:
				add_icon_item(ThemeDB.get_user_icon("looks_one"), tr(tags[idx]))
			1:
				add_icon_item(ThemeDB.get_user_icon("looks_two"), tr(tags[idx]))
			_:
				add_icon_item(ThemeDB.get_user_icon("looks_" + str(idx + 1)), tr(tags[idx]))


func get_tags() -> Array[String]:
	return tags
