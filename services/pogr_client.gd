class_name CustomPOGRClient
extends POGRClient

@export var discord: DiscordEmbeddedAppClient

func _ready() -> void:
	client_id = ProjectSettings.get("blazium/game/pogr_client_id")
	build_id = ProjectSettings.get("blazium/game/pogr_build_id")
	if !client_id || !build_id:
		print("Not using pogr analytics. client_id or build_id not set up")
		return
	log_updated.connect(_log_updated)
	if discord.is_discord_environment():
		pogr_url = "https://" + discord.client_id + ".discordsays.com/.proxy/blazium/pogr"
	var res :POGRResult = await init(OS.get_unique_id()).finished
	if res.has_error():
		push_error(res.error)
	await logs("started", "debug", "dev", "gameclient",  "user-event", {"association_id": OS.get_unique_id()}, {}).finished
	add_event("started")
	_add_start_data()
	_add_metrics()


func add_event(event_name: String):
	if !client_id || !build_id:
		print("Not using pogr analytics. client_id or build_id not set up")
		return
	await event("application_" + event_name,
		"game_" + event_name,
		"app_" + event_name,
		"succesful",
		"application_event",
		{"association_id": OS.get_unique_id()},
		{}).finished


func _add_start_data():
	if !client_id || !build_id:
		print("Not using pogr analytics. client_id or build_id not set up")
		return
	var store_name : = ProjectSettings.get("blazium/game/store_name")
	if discord.is_discord_environment():
		store_name = "discord"
	var platform = OS.get_name()
	if OS.has_feature("web_android"):
		platform = "WebAndroid"
	elif OS.has_feature("web_ios"):
		platform = "WebiOS"
	elif OS.has_feature("web_linuxbsd"):
		platform = "WebLinux"
	elif OS.has_feature("web_macos"):
		platform = "WebmacOS"
	elif OS.has_feature("web_windows"):
		platform = "WebWindows"
	await data({"association_id": OS.get_unique_id()},
		{
		"version": Engine.get_version_info(),
		"distribution_name": store_name,
		"arch": Engine.get_architecture_name(),
		"locale": OS.get_locale_language(),
		"model_name": OS.get_model_name(),
		"host_platform": platform,
		"processor_count": OS.get_processor_count(),
		"processor_name": OS.get_processor_name(),
		"unique_id": OS.get_unique_id(),
		"video_adapter_driver_info": " ".join(OS.get_video_adapter_driver_info()),
		"debug_build": OS.is_debug_build(),
		"is_sandboxed": OS.is_sandboxed(),
		}).finished


func _add_metrics():
	if !client_id || !build_id:
		print("Not using pogr analytics. client_id or build_id not set up")
		return
	await metrics({"engine_fps": Engine.get_frames_per_second(),
				"memory": OS.get_memory_info()}).finished


func _log_updated(command: String, p_logs: String):
	if command == "error":
		push_error("[POGRClient]: ", p_logs)
	else:
		print("[POGRClient]: ", command, " ", p_logs)
