extends Control

@export var entries_container: VBoxContainer
@export var prev_button: Button
@export var next_button: Button

var test_data = [
	{"rank": 1, "name": "WorldPlayer445", "score": 5},
	{"rank": 2, "name": "WorldPlayer446", "score": 3},
	{"rank": 3, "name": "WorldPlayer447", "score": 1},
	{"rank": 4, "name": "WorldPlayer448", "score": 1},
	{"rank": 5, "name": "WorldPlayer449", "score": 1},
	{"rank": 6, "name": "WorldPlayer450", "score": 1},
	{"rank": 7, "name": "WorldPlayer451", "score": 1},
	{"rank": 8, "name": "WorldPlayer452", "score": 1},
	{"rank": 9, "name": "WorldPlayer453", "score": 1},
	{"rank": 10, "name": "WorldPlayer454", "score": 1},
	{"rank": 11, "name": "WorldPlayer455", "score": 1},
	{"rank": 12, "name": "WorldPlayer456", "score": 1},
	{"rank": 13, "name": "WorldPlayer457", "score": 1},
	{"rank": 14, "name": "WorldPlayer458", "score": 1},
	{"rank": 15, "name": "WorldPlayer459", "score": 1},
	{"rank": 16, "name": "WorldPlayer460", "score": 1},
	{"rank": 17, "name": "player", "score": 1},
	{"rank": 18, "name": "WorldPlayer461", "score": 1},
	{"rank": 19, "name": "WorldPlayer462", "score": 1},
	{"rank": 20, "name": "WorldPlayer463", "score": 1},
	{"rank": 21, "name": "WorldPlayer464", "score": 1},
	{"rank": 22, "name": "WorldPlayer465", "score": 1},
	{"rank": 23, "name": "WorldPlayer466", "score": 1},
	{"rank": 24, "name": "WorldPlayer467", "score": 1},
	{"rank": 25, "name": "WorldPlayer468", "score": 1},
	{"rank": 26, "name": "WorldPlayer469", "score": 1},
	{"rank": 27, "name": "WorldPlayer470", "score": 1},
	{"rank": 28, "name": "WorldPlayer471", "score": 1},
	{"rank": 29, "name": "WorldPlayer472", "score": 1},
	{"rank": 30, "name": "WorldPlayer473", "score": 1},
	{"rank": 31, "name": "WorldPlayer474", "score": 1},
	{"rank": 32, "name": "WorldPlayer475", "score": 1},
	{"rank": 33, "name": "WorldPlayer476", "score": 1},
	{"rank": 34, "name": "WorldPlayer477", "score": 1},
]

const LEADERBOARD_ENTRY = preload("res://addons/blazium_shared_menus/leaderboard/leaderboard_entry.tscn")
const ENTRIES_PER_PAGE = 10
const PLAYER_COLOR = Color.ORCHID

var current_page = 0
var total_pages = 0
var player_index = -1

func _ready() -> void:
	for i in range(test_data.size()):
		if test_data[i]["name"] == "player":
			player_index = i
			break
	update_leaderboard(test_data)

func update_leaderboard(leaderboard_data: Array) -> void:
	for child in entries_container.get_children():
		child.queue_free()
	
	total_pages = ceil(float(leaderboard_data.size()) / ENTRIES_PER_PAGE) - 1
	current_page = clamp(current_page, 0, total_pages)
	
	var start_index = current_page * ENTRIES_PER_PAGE
	var end_index = min(start_index + ENTRIES_PER_PAGE, leaderboard_data.size())
	var regular_entries = end_index - start_index
	
	for i in range(start_index, end_index):
		var entry_data = leaderboard_data[i]
		create_entry(entry_data)
	
	var player_natural_position = player_index >= start_index && player_index < end_index
	if !player_natural_position && player_index >= 0:
		var fillers_needed = ENTRIES_PER_PAGE - regular_entries
		for i in range(fillers_needed):
			create_filler_entry()
		create_entry(leaderboard_data[player_index])
	
	if prev_button:
		prev_button.disabled = current_page == 0
		prev_button.focus_mode = Control.FOCUS_NONE if current_page == 0 else Control.FOCUS_ALL
		prev_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if current_page == 0 else Control.CURSOR_POINTING_HAND
	if next_button:
		next_button.disabled = current_page == total_pages
		next_button.focus_mode = Control.FOCUS_NONE if current_page == total_pages else Control.FOCUS_ALL
		next_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if current_page == total_pages else Control.CURSOR_POINTING_HAND

func create_entry(entry_data: Dictionary) -> void:
	var entry = LEADERBOARD_ENTRY.instantiate()
	
	entry.rank.text = str(entry_data["rank"])
	entry.player_name.text = entry_data["name"]
	entry.score.text = str(entry_data["score"])
	
	if entry_data["name"] == "player":
		entry.rank.modulate = PLAYER_COLOR
		entry.player_name.modulate = PLAYER_COLOR
		entry.score.modulate = PLAYER_COLOR
		entry.custom_minimum_size.y = 30
	
	entries_container.add_child(entry)

func create_filler_entry() -> void:
	var entry = LEADERBOARD_ENTRY.instantiate()
	
	entry.rank.text = ""
	entry.player_name.text = ""
	entry.score.text = ""
	entry.color_rect.color.a = 0
	
	entries_container.add_child(entry)

func _on_next_button_pressed() -> void:
	if current_page < total_pages:
		current_page += 1
		update_leaderboard(test_data)

func _on_previous_button_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_leaderboard(test_data)
