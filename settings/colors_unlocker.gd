class_name ColorUnlocker
extends TabContainer

@export var shirts: Array[ColorButton]
@export var pants: Array[ColorButton]
var items_enabled = {
	0: true
}

# STEAM DLCS


#ID	DLC TITLE	RELEASE DATE	STATUS
#3739180 	Project Hangman - POGR Drip
#3730900 	Project Hangman - Enjoyed the Game
#3730890 	Project Hangman - X Drip
#3730880 	Project Hangman - Blazium Drip
#3730870 	Project Hangman - Youtube Drip
#3730860	 Project Hangman - Twitch Drip
#3730850	 Project Hangman - Discord Drip

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var idx = 0
	if GlobalLobbyClient.is_discord_environment():
		# Enable discord skin
		items_enabled[7] = true
	for dlc_owned in GlobalLobbyClient.get_steam_dlcs():
		match dlc_owned["id"]:
			3739180: # POGR
				items_enabled[1] = true
			3730900: # ENJOYED
				items_enabled[2] = true
			3730890: # X
				items_enabled[3] = true
			3730880: # BLAZIUM
				items_enabled[4] = true
			3730870: # YOUTUBE
				items_enabled[5] = true
			3730860: # TWITCH
				items_enabled[6] = true
			3730850: # DISCORD
				items_enabled[7] = true
	for shirt in shirts:
		shirts[idx].disabled = !items_enabled.get(idx, false)
		shirts[idx].get_child(0).visible = !items_enabled.get(idx, false)
		pants[idx].disabled = !items_enabled.get(idx, false)
		pants[idx].get_child(0).visible = !items_enabled.get(idx, false)
		idx+= 1
