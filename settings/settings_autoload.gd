extends Node

var config := ConfigFile.new()

var user_locale:String

func _ready():
	get_window().min_size =  Vector2i(426, 240)
	

func _init() -> void:
	
	load_config()
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), config.get_value("Settings", "mute", false))
	
	var system_locale: String = TranslationServer.get_locale().split("_")[0]
	user_locale = config.get_value("Settings", "lang", "null")
	if user_locale == "null":
		user_locale = system_locale
		if user_locale.length() > 2:
			user_locale = system_locale
	if system_locale != user_locale:
		TranslationServer.set_locale(user_locale)
		config.set_value("Settings", "lang", user_locale)

	save_config()


func load_config() -> Error:
	return config.load("user://blazium.cfg")


func save_config() -> Error:
	return config.save("user://blazium.cfg")
