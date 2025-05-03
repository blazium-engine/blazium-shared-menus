extends Node

func _ready():
	login_steam()

func login_steam() -> bool:
	var result_init := Steam.steamInit(true, 3418850, true)
	if result_init["status"] != 1:
		print("[SteamLogin]: ", result_init["verbal"])
		return false
	Steam.get_ticket_for_web_api.connect(_get_ticket_for_web_api)
	Steam.getAuthTicketForWebApi("blazium")
	return true

func _get_ticket_for_web_api(auth_ticket: int, result: int, ticket_size: int, ticket_buffer: PackedByteArray):
	#print(ticket_buffer.hex_encode())
	pass
