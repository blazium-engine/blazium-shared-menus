extends DiscordEmbeddedAppClient


func _init() -> void:
	log_updated.connect(_log_updated)


func _log_updated(command: String, message: String):
	print("[DiscordEmbeddedAppClient]: ", command, ": ", message)

func discord_access_code_flow():
	var discord_result:DiscordEmbeddedAppResult = await is_ready().finished
	if discord_result.has_error():
		push_error(discord_result.error)
		return
	# Authorize the player if it's a new login
	discord_result = await authorize("code", "", "none", ["identify"]).finished
	if !discord_result.data.has("code"):
		push_error(discord_result.error)
		return
	return discord_result.data.get("code", "")
