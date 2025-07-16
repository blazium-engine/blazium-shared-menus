extends Node

var config := ConfigFile.new()

var user_locale:String


func _ready():
	get_window().min_size =  Vector2i(426, 240)


func _init() -> void:
	load_config()
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), config.get_value("Settings", "mute", false))
	
	save_config()


func load_config() -> Error:
	return config.load("user://blazium.cfg")


func save_config() -> Error:
	return config.save("user://blazium.cfg")
