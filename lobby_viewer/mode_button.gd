@tool
extends CustomOptionButton

var options = ["Mode: Normal", "Mode: Individual", "Mode: Co-op", "Mode: Last Wrong Loses"]
var icons = ["accessibility", "person", "groups", "sports_kabaddi"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for idx in range(options.size()):
		add_icon_item(ThemeDB.get_user_icon(icons[idx]), options[idx])
