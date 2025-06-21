extends Node


func _ready() -> void:
	get_window().min_size =  Vector2i(426, 240)
	
	var config := ConfigFile.new()
	config.load("user://blazium.cfg")
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), config.get_value("Settings", "mute", false))
	
	var system_locale: String = TranslationServer.get_locale().split("_")[0]
	var user_locale: String = config.get_value("Settings", "lang", "null")
	if user_locale == "null":
		user_locale = system_locale
		if user_locale.length() > 2:
			user_locale = system_locale
	if system_locale != user_locale:
		TranslationServer.set_locale(user_locale)
		config.set_value("Settings", "lang", user_locale)
		config.save("user://blazium.cfg")
